#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );

use Test::HTtapTP ':cors_ok';
use Test::More;
use Sys::Hostname 'hostname';

use Otter::WebConfig qw( config_extract );


sub main {
    plan tests => 3;
    my $cfg = config_extract();

    my $ok = 1;
    $ok &= is(ref($cfg), 'ARRAY', 'got a list');

    my $hostname = hostname();
    my @here = grep { $hostname eq $_->{hostname} } @$cfg;
    $ok &= cmp_ok(scalar @here, '>', 0,
                  "list includes this machine ($hostname)");

    my $WEBDIR = Otter::Paths->webdir;
    my @here_me = grep { $WEBDIR eq $_->{write} } @here;
    $ok &= cmp_ok(scalar @here_me, '==', 1,
                  "list includes this WEBDIR ($WEBDIR) once");

    diag explain { cfg => $cfg } unless $ok;

    return 0;
}


main();
