#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 otter-dev );

use Test::HTtapTP ':cors_ok';
use Test::More;

use URI;
use List::MoreUtils 'uniq';
use LWP::UserAgent;

use Bio::Otter::Server::Config; # to find the designations
use Otter::WebNodes; # to find self


my $version;
my $ua;

sub main {
    plan tests => 2;
    my @version = desig2versions();
    cmp_ok(scalar @version, '>', 3, 'some Otter Server versions');

    $ua = LWP::UserAgent->new;
    $ua->env_proxy; # XXX: report it
    my $prog = $ENV{SCRIPT_URI} || $0;
    $ua->agent("$prog ");
    $ua->timeout(10);
    # We intend to call the Apache server which is running us,
    # and this can lead to deadlock for non-threaded servers.

    # Otter Server won't look nice for us if we don't give some auth.
    #
    # CGI requests may come with some from the browser.
    my $q = $ENV{GATEWAY_INTERFACE} ? CGI->new : undef;
    if ($ENV{HTTP_COOKIE}) {
        diag "Got implicit cookies from browser";
        $ua->default_header(Cookie => $ENV{HTTP_COOKIE});
    } elsif ($q && $q->param('cookie')) {
        diag "Got explicit cookies from GET query";
        $ua->default_header(Cookie => $q->param('cookie'));
    } else {
        warn "I have no cookies to offer to Otter Servers";
    }
    # XXX:DUP there is code for "obtaining" cookies in team_tools.git bin/curl_otter bin/webvm-cgi-run

    subtest "All Otters" => sub {
        plan tests => scalar @version;
        foreach my $major (@version) {
            $version = $major;
            subtest "Otter v$version" => \&otter_server_tt;
        }
    };
    return 0;
}

sub desig2versions {
    my $desig = Bio::Otter::Server::Config->designations;
    my $desig_re = qr{^(\d{2,4})(?:\.\d+)?$};
    my @version = map { if ($desig->{$_} =~ $desig_re) {
        $1;
    } else {
        die "Didn't understand desig($_ => $desig->{$_}) with $desig_re";
    } } keys %$desig;
    @version = uniq(sort @version);

    die unless wantarray;
    return @version;
}

sub otter_server_tt {
    my @part = qw( test );
    push @part,  $version < 73 ? 'get_otter_config' : 'get_config?key=otter_config';
    plan tests => scalar @part;

    my $server_here = Otter::WebNodes->new_cgi->base_uri;
    my $otter = URI->new_abs("/cgi-bin/otter/$version", $server_here);
    foreach my $part (@part) {
        my $uri = "$otter/$part";
        my $resp = $ua->get($uri);
        if ($part eq 'test' && $resp->code eq '410') {
            ok(1, $uri);
          SKIP: {
                skip "v$version is 410 Gone", @part - 1;
            }
            last;
        } else {
            ok($resp->is_success, $uri) or
              diag join "\n",
                ($resp->request->as_string,
                 $resp->status_line, $resp->headers_as_string, $resp->decoded_content);
        }
    }
}

main();
