=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Otter::TestUA;
use strict;
use warnings;

use LWP::UserAgent;
use CGI;
use List::MoreUtils qw( uniq );
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
    $ua->env_proxy;
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

    # Report the proxy
    # XXX:DUP Bio::Otter::Lace::Client->ua_tell_proxies
    my %info;
    @info{qw{ http https }} = map { defined $_ ? $_ : 'none' }
      $ua->proxy([qw[ http https ]]);
    if ($info{http} eq $info{https}) {
        $info{'http[s]'} = delete $info{http};
        delete $info{https};
    }
    my @nopr = @{ $ua->{no_proxy} }; # there is no get accessor
    $info{no_proxy} = join ',', uniq(@nopr) if @nopr;
    diag explain { ua_proxy => \%info };

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
