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


require Otter::Paths;

sub import {
    my ( $package, @tags ) = @_;

    if ($ENV{APACHE_DEVEL}) {
        # System load debugging
        # Probably not needed when SangerPaths gone
        require Otter::LoadReport;
    }

    return Otter::Paths->import(@tags);
}

1;
