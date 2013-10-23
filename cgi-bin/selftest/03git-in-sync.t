#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More;

use Try::Tiny;
use LWP::UserAgent;
use XML::XPath;
use XML::XPath::XMLParser;
use YAML 'Dump';

use Otter::WebNodes;
use WebVM::Util qw( gits_info );


sub main {
    # Are we live or dev?
    my $host_type = Otter::WebNodes->new_cgi->type;
    my $dev_live = {qw{ live live staging live  dev dev sandbox dev }}->
      {$host_type} || die "Unknown host_type $host_type";

    my %want_repos = ('' => [ 'webvm', 'master' ],
                      'apps/webvm-deps' => [ 'webvm-deps', 'master' ],
                      'data/otter' => [ 'server-config', $dev_live ]);
    my (%want_detail, %want);
    plan tests => 1 + keys %want_repos;

    my ($have_detail, %have, %have_spare);
    my $ok = 1;

    try {
        my $WEBDIR = Otter::Paths->webdir;

        ### Fetch commitid for expected repos
        #
        while (my ($name, $repo_ref) = each %want_repos) {
            my @ciid8 = git_latest(@$repo_ref);
            $want_detail{$name} = { recent_commits => \@ciid8 };
            $want{$name} = { ciid8 => $ciid8[0], dirty => 'clean' };
        }
        # It could have run in parallel...

        ### Get info about the Git repositories here
        #
        local $ENV{PATH} = '/bin:/usr/bin';
        $have_detail = gits_info($WEBDIR);
        # key = $pathname, value = \%info

        # Make relative names
        while (my ($path, $info) = each %$have_detail) {
            my $name = $path;
            $name =~ s{^\Q$WEBDIR\E(/|$)}{}
              or die "Can't trim ^$WEBDIR off $name";
            my @i = $info->{describe} =~ m{(?:^|-g)([0-9a-f]{8})(?:-(dirty))?$}
              or die "Can't extract ciid8 from $$info{describe} for $name";
            $have{$name} = { ciid8 => $i[0], dirty => $i[1] || 'clean' };
        }

        # Separate "extra" repos found
        foreach my $name (keys %have) {
            next if $want{$name};
            $have_spare{$name} = delete $have{$name};
        }
    } catch {
        $ok = 0;
        fail("Couldn't get necessary info: $_");
    };

  SKIP: {
        skip scalar keys %want_repos, "Need the info" unless $ok;

        local $TODO;
        $TODO = 'this is a sandbox, we expect work-in-progress'
          if $host_type eq 'sandbox';

        foreach my $name (sort keys %want) {
            my $recent = $want_detail{$name}{recent_commits};
            my $n = @$recent - 1;
            my $diagnosis;
            if (defined $have{$name}) {
                my ($found_idx) =
                  grep { $have{$name}{ciid8} eq $recent->[$_] } (0..$n);
                $diagnosis = (defined $found_idx
                              ? "$found_idx commit(s) behind"
                              : "Ahead or >$n commits behind");
            } else {
                $diagnosis = 'Absent';
            }
            $ok &= is_deeply($have{$name}, $want{$name},
                             "Expected repository '$name' up-to-date")
              || diag $diagnosis;
        }
        $ok &= is(scalar keys %have_spare, 0, 'No unexpected repos')
          || diag explain [ keys %have_spare ];
    }

    diag Dump({( _01_want_repos => \%want_repos,
                 _02_want_detail => \%want_detail,
                 _03_want => \%want,
                 _04_have_detail => $have_detail,
                 _05_have => \%have,
                 _06_have_spare => \%have_spare )})
      unless $ok;

    return 0;
}


# Ask our gitweb server, return list of --abbrev=8 commitids
sub git_latest {
    my ($name, $branch) = @_;

    my $ref = "refs/heads/$branch";
    my $url = "http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/$name.git;a=atom;h=$ref";

    my $ua = LWP::UserAgent->new;
    $ua->agent("$0 ");
    $ua->timeout(10);
    $ua->env_proxy;

    my $resp = $ua->get($url);
    if ($resp->is_success) {
        my $xp = XML::XPath->new(xml => $resp->decoded_content);
        my $nodeset = $xp->find('/feed/entry/id');
        my @ciid;
        foreach my $node ($nodeset->get_nodelist) {
            my $id = XML::XPath::XMLParser::as_string($node);
            # <id>http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/webvm.git;a=commitdiff;h=f29b84f6a71b9631066d3764995d0b6c5d00fd93</id>
            my ($ciid) = $id =~ m{h=([0-9a-f]{40})}
              or die "Cannot extract ciid from $id";
            push @ciid, substr($ciid, 0, 8);
        }
        if (!@ciid) {
            diag $resp->decoded_content;
            die "Fetch of $url returned valid atom XML but no commitid";
        }
        return @ciid;
    } else {
        die "Fetch of $url failed: ".$resp->status_line;
    }
}


main();
