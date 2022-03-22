=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package WebVM::Util;
use strict;
use warnings;

use Try::Tiny;
use File::Find;


use base 'Exporter';
our @EXPORT_OK = qw( gits_info pipefrom_with );


sub gits_info {
    my ($webdir) = @_;

    # Find Git repositories
    my %repo;
    find({ wanted => fffilter($webdir, \%repo),
           no_chdir => 1,
           follow => 1,
           follow_skip => 2,
         }, $webdir);

    return \%repo;
}


sub fffilter {
    my ($webdir, $repo_hash) = @_;
    return sub { # File::Find "wanted" filter
        # pathname is in $_; an lstat($_) has happened
        return unless -d _; # not interested in files
        if (m{^(.*)/\.git$}) {
            # looks enough like a Git working copy
            my $repo = $1;
            my $with = { cd => $repo, stderr => 1 };
            $repo_hash->{$repo}{describe} = pipefrom_with
              (qw( git describe --tags --long --always --abbrev=8 --dirty ),
               $with);
            $repo_hash->{$repo}{status} = try {
                pipefrom_with(qw( git status --ignore-submodules --ignored ), $with);
                # --ignore not not supported in 1.7.9.5 (on Lucid)
            } catch {
                warn "git status($repo): retry without --ignore*";
                pipefrom_with(qw( git status ), $with);
            };
            for ($repo_hash->{$repo}{status}) {
                s{^#\t}{#       }mg;
                s{^#   \(use "git .* to .*\)\n}{}mg;
            }
            $File::Find::prune = 1;
        } elsif (m{/ensembl-branch-\d+$}) {
            # huge tree, not expected to contain interesting stuff
            $File::Find::prune = 1;
        }
        # else carry on filtering...
        return;
    };
}


sub pipefrom_with {
    my (@cmd) = @_;
    my $with = ref($cmd[-1]) ? pop @cmd : { };

    my $pid = open my $fh, '-|';
    if (!defined $pid) {
        die "pipe from fork failed: $!";
    } elsif (!$pid) {
        # child
        if ($with->{stderr}) {
            open STDERR, '>&', \*STDOUT or die "Dup: $!";
        }
        if (my $cd = $with->{cd}) {
            chdir $cd or die "chdir $cd: $!";
        }
        exec @cmd;
        die "exec @cmd: $!";
    } # else parent
    my $out = do { local $/; <$fh> };
    chomp $out;

    my @opt = %$with;
    close $fh or die "piped from @cmd \{@opt}: failed $! / $? / $out";

    return $out;
}


1;
