package SangerPaths;

use strict;
use warnings;

use Otter::PerlVersion;

require Otter::Paths;


sub import {
    my ( $package, @tags ) = @_;

    return Otter::Paths->import(@tags);
}

1;
