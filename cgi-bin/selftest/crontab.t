#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::Paths qw( HTtapTP-0.03 );
use Otter::WebCrontab qw( invent_crontab );

use Test::HTtapTP;
use Test::More tests => 2;


sub main {
    $ENV{PATH} = '/bin:/usr/bin';

    open my $fh, '-|', "/usr/bin/crontab", "-l"
      or die "Pipe from crontab: $!";
    my $got = do { local $/; <$fh> };
    close $fh;
    is($?, 0, 'crontab -l: exit code');

    is($got, invent_crontab(), 'crontab -l: contents');

    return;
}

main();
