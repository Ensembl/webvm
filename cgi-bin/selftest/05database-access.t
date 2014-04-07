#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 otter-dev );
use Test::HTtapTP ':cors_ok';
use Test::More;

use Bio::Otter::Server::Config;

use DBI;
use Sys::Hostname 'hostname';
use Try::Tiny;
use List::Util qw( min max sum );

sub main {
    my $D = Bio::Otter::Server::Config->databases;
    my @essential = qw( otterlive );
    plan tests => @essential + (keys %$D) + 1;

    foreach my $key (@essential) {
        ok($D->{$key}, "found database server config for '$key'");
    }

    my %t = (hostname() => time());
    foreach my $key (sort keys %$D) {
        local $TODO;
        $TODO = $key =~ /BROKEN/ ? "expected to not work" : '';
        subtest $key => sub {
            my $t_db = db_tt($key, $D->{$key});
            $t{$key} = $t_db if defined $t_db;
        };
    }

    my %cmp =
      (avg => int(sum(values %t) / keys %t),
       min => min(values %t),
       max => max(values %t));
    $cmp{diff} = $cmp{max} - $cmp{min};
    $t{_cmp} = \%cmp;

    cmp_ok($cmp{diff}, '<', 30, "time skew")
      or diag explain \%t;

    return;
}

sub db_tt {
    my ($key, $db) = @_;
    plan tests => 1;

    my $t_db = try {
        my ($name, $host) = ($db->name, $db->host);
        my $dbh = DBI->connect( $db->spec_DBI );
        my ($t_db) = $dbh->selectrow_array(q{ SELECT unix_timestamp(now()) });
        return $t_db;
    } catch {
        return "ERR:$_";
    };

    if (like($t_db, qr{^\d{8,}$}, "get time from database server $key")) {
        return $t_db;
    } else {
        return;
    }
}

main();
