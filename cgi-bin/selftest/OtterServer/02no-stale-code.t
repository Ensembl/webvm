#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 otter-dev );

use Test::HTtapTP ':cors_ok';
use Test::More;

use Bio::Otter::Version;
use Bio::Otter::Server::Config; # to find the designations
use Otter::WebNodes;
use WebVM::GitLatest;


my ($version, $lookup);

sub main {
    plan tests => 2;

    # Are we live or dev?
    my $host_type = Otter::WebNodes->new_cgi->type;

    # Which Otter versions are expected
    my @version = Bio::Otter::Server::Config->extant_versions;
    cmp_ok(scalar @version,
           '>', 1, # live & dev
           'some Otter Server versions');

    $lookup = WebVM::GitLatest->new;

    subtest "All Otters" => sub {
        local $TODO;
### Not marking TODO because TODO-fail in subtest is invisible to tap-parser 0.0.2
#        $TODO = 'this is a sandbox, we expect work-in-progress'
#          if $host_type eq 'sandbox';

        plan tests => scalar @version;
        foreach my $major (@version) {
            $version = $major;
            subtest "Otter v$version" => \&otter_server_tt;
        }
    };
    return 0;
}


sub otter_server_tt {
    plan tests => 1;

    my $code_vsn = otter_version($version);
    my $repo = "anacode/ensembl-otter.git"; # the dir in gitweb

  SKIP: {
        skip "Otter v$version is absent here, $code_vsn", 1
          if $code_vsn =~ /^only have /; # absence is covered elsewhere

        ### What is installed here?
        #
        my ($ciid_len, $got_ciid);
        my $br = "humpub-branch-$version";
        if ($code_vsn =~ m{^humpub-release-(\d+)-(\d+)$}) {
            # Exactly tagged (humpub-release-76-06).
            # Convert to ciid using gitweb.
            my $ref = "refs/tags/$code_vsn";
            $ciid_len = 8;
            ($got_ciid) = $lookup->latest_ciid($repo, $ref, $ciid_len);
        } elsif (my ($what, $ciid) = $code_vsn =~
                 m{^humpub-release-\Q$version\E-(\w+)-\d+-g([a-f0-9]{4,40})$}) {
            # Dev (humpub-release-78-dev-28-gf676a72)
            # or release-plus (humpub-release-75-24-1-g43fe0be)
            $br = 'master' if $what eq 'dev'
              && $version eq Bio::Otter::Version->version;
            $got_ciid = $ciid;
            $ciid_len = length($ciid);
        } else {
            # unrecognised, probably fail
            $got_ciid = $code_vsn;
        }

        ### What is latest in central?
        #
        my @want = $lookup->latest_ciid($repo, "refs/heads/$br", $ciid_len || 8);


        # Compare
        my $want_ciid = $want[0];
        my $ok = is($got_ciid, $want_ciid, "Otter $version at head of branch $br ?");
        diag "Libs for otter$version are $code_vsn" if !$ok;
        diag( WebVM::GitLatest->diagnose($got_ciid, @want) ) if !$ok && $ciid_len;
    }

    return;
}


# Fork another Perl to ask different version of Otter API what it is
sub otter_version {
    my ($version) = @_;

    my $code = <<"CODE";
 use strict;
 use warnings;
 BEGIN { \*STDERR = \*STDOUT } # 2>&1
 use Otter::Paths qw( otter$version );
 use Bio::Otter::Git;
 print Bio::Otter::Git->param('head');
CODE

    local $ENV{PATH} = '/bin:/usr/bin';
    my $WEBDIR = Otter::Paths->webdir;
    my ($perl) = ($^X =~ m{^(/[-/a-z0-9.]+)$})
      or die "Can't detaint Perl exe $^X";
    open my $fh, '-|', ($perl, -I => "$WEBDIR/lib/bootstrap",
                        -e => $code)
      or die "Failed to pipe from Perl for v$version: $!";
    my $out = do { local $/ = undef; <$fh> };

    if (close $fh) {
        # ok
    } elsif (0 == $! && 0x200 == $? && $out =~
             /Cannot find Otter Server.*Available are (\([a-z0-9 ]+\))/s) {
        # error from Otte::Paths, quite likely in sandbox
        $out = "only have $1";
    } else {
        # fail
        my $err = ($!) ? "Failed: $!" : sprintf('Failed, $?=0x%03X', $?);
        $out =~ s/^/\t/mg;
        $out = "$err.  Other output\n$out";
    }

    return $out;
}


main();
