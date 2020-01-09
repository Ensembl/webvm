=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package SangerPaths;

use strict;
use warnings;


=head1 NAME

SangerPaths - webteam SangerPaths, emulation for Anacode

=head1 DESCRIPTION

This module provides extra elements on C<@INC> as requested by tag.
It also hooks the Perl interpreter self-wrap (shebang override)
module.

It aims to be a workalike for the central SangerPaths, for the subset
of packages that we need.

=head2 Lifetime

This module is "slightly legacy", in that CGI scripts can switch from

 use SangerPaths qw( foo );

to

 use Otter::PerlVersion;
 use Otter::LoadReport;
 use Otter::Paths qw( foo );

once they no longer run on old webservers.


=head1 CAVEATS

Failure to find requested items is not (yet) fatal, as it was on the
original.

L<Otter::PerlVersion> is not intended for production use, but I'm
leaving it available since it is a no-op unless configured to act.


=head1 AUTHOR

mca@sanger.ac.uk

=cut

use Otter::PerlVersion;
use Otter::LoadReport; # for diagnosing load spikes

require Otter::Paths;

sub import {
    my ( $package, @tags ) = @_;

    return Otter::Paths->import(@tags);
}

1;
