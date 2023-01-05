=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Otter::PerlVersion;

use strict;
use warnings;


=head1 NAME

Otter::PerlVersion - ensure script runs under the configured Perl

=head1 SYNOPSIS

 # in /my/script.pl
 use Otter::PerlVersion;

 # what it can do
 export OTTER_PERL_EXE=/my/specific/perl
 export OTTER_PERL_INC=$WEBDIR/lib/bootstrap:/bar
 /any/old/perl -T -I $WEBDIR/lib/bootstrap /my/script.pl $args

=head1 DESCRIPTION

This module gets around the problem of configuring the Perl version,

=over 4

=item * from the environment

=item * with taint checking enabled

=item * without modifying the script

=item * without using /usr/bin/env

Note that C<< #! /usr/bin/env perl -T >> doesn't work.

=back

for a small runtime cost and some complexity.

We use it in the development setting, but not in production.

=head2 Alternative method - shell script wrapper

The previous "local Apache" Otter Server interposed a shell script, by
use of Apache's C<ScriptAliasMatch> directive, to do this job.

That allowed the wrapping process to be done without changes to the
CGI scripts.  Since then, then have been modified to detaint an
environment variable onto C<@INC>.


=head1 CAVEATS

This must happen early, and specifically before C<chdir> or any
modification of C<@ARGV> happens.

=head2 Terminating the re-exec loop

The absence of C<< $ENV{OTTER_PERL_EXE} >> is the condition for
continuing with normal program execution.  Beware setting this
variable during compilation!

=head2 Detainting

Many things are gratuitously detainted during this process.

We must trust the webserver to give us sensible environment.  The
subsequent Perl invocation will continue to be taint checked, and
anything re-imported from the environment will be tainted.


=head1 AUTHOR

mca@sanger.ac.uk

=cut


sub selfwrap {
    # The OTTER_PERL_INC was enough to find this library.
    # We may now discover that we are running the wrong Perl,
    # so start again with the correct one.
    if (my $want_perl = delete $ENV{OTTER_PERL_EXE}) {
        my $inc = delete $ENV{OTTER_PERL_INC} || q{};
        my @libs = split ':', $inc;
        local $ENV{PATH} = detaint($ENV{PATH}); # we intend not to use it, but exec insists and we don't insist $want_perl is absolute

        # Clues for those reading %ENV later
        local $ENV{OTTER_PERL_EXE_used} = $want_perl;
        local $ENV{OTTER_PERL_INC_used} = $inc;

        my ($perl, @opt) = split / +/, $want_perl;
        my @cmd = map { detaint($_) }
          ($perl, @opt, (map { -I => $_ } @libs), -Tw => $0, @ARGV);
        { exec @cmd; }
        die "$0: Cannot find OTTER_PERL_EXE=$want_perl for\n @cmd";
    } else {
#        warn join "\n  ", "Running under Perl $^X = $] = $^V and \@INC is", @INC;
        die "Expected taint mode, something went wrong" unless ${^TAINT};
    }
    return ();
}

sub detaint {
    my ($txt) = @_;
    ($txt) = $txt =~ m{\A(.*)\z};
    return $txt;
}

sub import {
    selfwrap();
    return ();
}


1;
