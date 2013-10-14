#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More tests => 2;

ok(1, "The only reason for this test to fail is a transport error");
diag("Or maybe a library error");

ok(5, "I would offer a TODO-fail test here, but tap-parser.js does not understand TODO marks"); # XXX: new version available by now?  or fix it?
#local $TODO = "Make everything work";
#fail("This test should not be necessary");
