#! /usr/bin/perl -T
# Copyright [2018-2020] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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
use File::Slurp 'read_dir';
use List::MoreUtils 'uniq';


my ($version, $lookup);

sub main {
    plan tests => 2;

    # Are we live or dev?
    my $host_type = Otter::WebNodes->new_cgi->type;

    # Which Otter versions are expected?
    my @version = Bio::Otter::Server::Config->extant_versions;
    cmp_ok(scalar @version,
           '>', 1, # live & dev
           'some Otter Server versions');

    # What else is kicking around?
    my @more = (vsn_dir("lib/otter"), vsn_dir("cgi-bin/otter"));
    @version = sort { $a <=> $b } uniq(@version, @more);

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

sub vsn_dir {
    my ($rel_path) = @_;
    my $otterlace_server_root = Otter::Paths->code_root;
    my $src = "$otterlace_server_root/$rel_path";
    my @vsn = grep { /^\d{2,4}$/ && -d "$src/$_" } read_dir($src);
    die unless wantarray;
    return @vsn;
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
        my ($ciid_len, $got_ciid) = (8);
        my $br = "humpub-branch-$version";
        if ($code_vsn =~ m{^humpub-release-(\d+)-(\d+)$}) {
            # Exactly tagged (humpub-release-76-06).
            # Convert to ciid using gitweb.
            my $ref = "refs/tags/$code_vsn";
            ($got_ciid) = $lookup->latest_ciid($repo, $ref, $ciid_len);
        } elsif (my ($what, $ciid) = $code_vsn =~
                 m{^humpub-release-\Q$version\E-(\w+)-\d+-g([a-f0-9]{4,40})$}) {
            # Dev (humpub-release-78-dev-28-gf676a72)
            # or release-plus (humpub-release-76-06-4-g660a0f2)
            $br = 'master' if $what eq 'dev'
              && Bio::Otter::Version->version # as provided by Otter::Paths
                eq $version;
            $got_ciid = $ciid;
            $ciid_len = length($ciid);
        } elsif ($code_vsn eq "humpub-release-$version-dev") {
            # first commit on new dev branch, ciid is not available
            # because Bio::Otter::Git didn't record that
            $br = 'master';
            $got_ciid = 'unknown:first_on_new_dev_branch';
        } else {
            # unrecognised, probably fail
            $br = 'master';
            $got_ciid = "unknown:$code_vsn";
        }

        ### What is latest in central?
        #
        my @want = $lookup->latest_ciid($repo, "refs/heads/$br", $ciid_len || 8);
        if (!@want && $br ne 'master') {
            my $v_dev = Bio::Otter::Version->version;
            diag "Otter::Paths gave me $v_dev as the dev version,\n".
              "but using master because I found no commits on $br";
            $br = 'master';
            @want = $lookup->latest_ciid($repo, "refs/heads/$br", $ciid_len || 8);
        }

        # Compare
        my $want_ciid = @want ? $want[0] : 'unknown-bad-want_ciid';
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
        # error from Otter::Paths, quite likely in sandbox
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
