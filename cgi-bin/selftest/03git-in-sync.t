#! /usr/bin/perl -T
# Copyright [2018-2024] EMBL-European Bioinformatics Institute
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
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More;

use Try::Tiny;
use YAML 'Dump';

use Otter::WebNodes;
use WebVM::Util qw( gits_info );
use WebVM::GitLatest;


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
    my $lookup = WebVM::GitLatest->new;

    try {
        my $WEBDIR = Otter::Paths->webdir;

        ### Fetch commitid for expected repos
        #
        while (my ($name, $repo_ref) = each %want_repos) {
            my ($repo_dir, $branch) = @$repo_ref;
            my @ciid8 = $lookup->latest_ciid("anacode/$repo_dir.git",
                                             "refs/heads/$branch", 8);
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
            my $src = $want_repos{$name}[0];
            my $recent = $want_detail{$name}{recent_commits};
            $ok &= is_deeply($have{$name}, $want{$name},
                             "Expected repository '$name' ($src) up-to-date")
              || diag( WebVM::GitLatest->diagnose($have{$name}{ciid8}, @$recent) );
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


main();
