package Otter::TestUA;
use strict;
use warnings;

use LWP::UserAgent;
use CGI;
use Test::More;

use base 'Exporter';
our @EXPORT_OK = qw( make_ua );


=head1 NAME

Otter::TestUA - set up an L<LWP::UserAgent>

=head1 DESCRIPTION

Creates and returns an L<LWP::UserAgent> for use in cgi-bin/selftest/

May instantiate a L<CGI>, which could eat your POST data.

=cut

sub make_ua {
    my ($q) = @_;
    $q ||= CGI->new if $ENV{GATEWAY_INTERFACE};

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy; # XXX: report it
    my $prog = $ENV{SCRIPT_URI} || $0;
    $ua->agent("$prog ");
    $ua->timeout(10);
    # We intend to call the Apache server which is running us,
    # and this can lead to deadlock for non-threaded servers.

    diag <<AUTH;
Otter Server will forbid requests which are not internal or
authorised.

Requests to non-DEVEL servers which are did not come through a ZXTM
will not have the "HTTP_CLIENTREALM:sanger", so they need a cookie.
Give your browser one at http://www.sanger.ac.uk/my_login.shtml

AUTH

    # CGI requests may come with some from the browser.
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

    return $ua;
}


1;
