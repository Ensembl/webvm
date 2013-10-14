#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More tests => 3;

use Sys::Hostname 'hostname';
use Socket;

my $hostname = hostname();
diag("hostname = $hostname");

my $host_dns = pipefrom(host => $hostname);
diag("host_dns = $host_dns");

my $dns_re = qr{\A(\S+) has address (\S+)\n\Z};
like($host_dns, $dns_re, "got IP from host(1)");
my ($fqdn, $dns_ip) = $host_dns =~ $dns_re;
diag("dns_ip = $dns_ip\nfqdn = $fqdn");

my $packed_ip = gethostbyname($hostname);
ok(defined $packed_ip, "got IP from gethostbyname(3)");
my $nss_ip = defined $packed_ip ? inet_ntoa($packed_ip) : 'nss fail?';
diag("nss_ip = $nss_ip");

is($nss_ip, $dns_ip, "nss_ip eq dns_ip");

diag <<"WHY";
\n\n    Why test this?

    Because when it is broken, weird and confusing stuff will happen
    to any connections that go direct from the host to itself.
    Connections from anywhere else, to anywhere else, or via a proxy
    will most likely not be affected.\n
WHY

sub pipefrom {
    my (@cmd) = @_;
    local $ENV{PATH} = '/bin:/usr/bin';
    my $pid = open my $fh, '-|', @cmd
      or die "pipefrom @cmd: $!";
    my $out = do { local $/; <$fh> };
    close $fh
      or return "ERR: pipefrom @cmd: exit code $! / $?";
    return $out;
}

