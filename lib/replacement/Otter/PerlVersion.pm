package Otter::PerlVersion;

use strict;
use warnings;


sub selfwrap {
    # The OTTER_PERL_INC was enough to find this library.
    # We now discover that we are running the wrong Perl,
    # so start again with the correct one.
    #
    # We detaint many things here.  We must trust the webserver to
    # give us sensible environment.
    if (my $want_perl = delete $ENV{OTTER_PERL_EXE}) {
        my @libs = split ':', delete $ENV{OTTER_PERL_INC} || q{};
        $ENV{PATH} = detaint($ENV{PATH}); # we are not using it, but exec insists
        exec detaint($want_perl), (map {( -I => detaint($_) )} @libs), -Tw => detaint($0);
        die "$0: Cannot find the correct Perl '$want_perl'";
    } else {
        warn join "\n  ", "Running under Perl $^X = $] = $^V and \@INC is", @INC;
#require DBI;
    }
}

sub detaint {
    my ($txt) = @_;
    ($txt) = $txt =~ m{\A(.*)\z};
    return $txt;
}

selfwrap();

1;
