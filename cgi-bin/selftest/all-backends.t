#! /usr/bin/perl -T
# Copyright [2018-2021] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 otter-dev );

use YAML 'Load';
use Try::Tiny;
use List::MoreUtils qw( uniq );
use Test::HTtapTP ':cors_ok';
use Test::More;

use Bio::Otter::Server::Config; # to find the designations
use Otter::WebNodes; # to find self
use Otter::TestUA 'make_ua';


my ($ua, @all_srv);

sub main {
    my $me = Otter::WebNodes->new_cgi;
    unless ($me->is_frontend) {
        plan skip_all => "Not running in a front-end context";
        # on the commandline, possibly we need to _get_ one?  all?
    }
    plan tests => 3;

    # $me was populated without a backend list.  Get the fixed up one.
    @all_srv = Otter::WebNodes->listnew_fixed;
    ($me) = grep { $me->base_uri eq $_->base_uri } @all_srv;
# ($me) = grep { $_->base_uri =~ m{otter\.dev\.} } @all_srv; # test something else?
    ok(($me && $me->is_frontend), "found self in the fixed up frontends list")
      or die "cannot continue";

    # Get the current test or live release.  We'll see that it is
    # served by all the backends.
    #
    # Taking test in preference, because now live=75 doesn't serve the
    # host info
    my $desig = Bio::Otter::Server::Config->designations;
    my ($version) = ($desig->{test} || $desig->{live}) =~ m{^(\d{2,4})(\.|$)};
    if (!$version) {
        diag explain { desig => $desig };
        die "Couldn't get live release version";
    }

    # Pick the test URL
    my $otter_test = URI->new_abs("/cgi-bin/otter/$version/test", $me->base_uri);

    # List expected backend(s)
    my @backend_uri = $me->frontend_contains;
    cmp_ok(scalar @backend_uri, '>', 0, "Got some expected backend URIs");
    my %host = # key = fqdn, value = URI (not yet seen) || undef (seen)
      map {( $_->host => $_ )} @backend_uri;
    diag explain join ' ', 'hostnames = ', sort keys %host;

    subtest tick_off_backends => sub { check_backends($otter_test, %host) };

    return 0;
}

# Expand unqualified hostname
sub FQDNify {
    my ($host, @srv) = @_;

    my @fqdn = map { $_->vhost } @srv; # all possible & expected
    @fqdn = uniq(grep { m{^\Q$host\E\.} } @fqdn); # the match

    if (1 == @fqdn) {
        return $fqdn[0];
    } else {
        diag "fqdn = @fqdn";
        die @fqdn." matches for hostname $host";
    }
}

sub check_backends {
    my ($otter_test, %host) = @_;

    plan tests => scalar keys %host;
    # We may also emit fail() not included in this plan

    $ua = make_ua();
    my $tries = (keys %host)
      * 4; # factor plucked from nowhere

    for (my $i=1; $i <= $tries; $i++) {
        my $resp = $ua->get($otter_test);

        if ($resp->is_success) {
            # Fetch the webserver hostname from test info
            my $resp_host = try {
                my ($test_info) = Load($resp->decoded_content);
                my @k = keys %$test_info;
                $test_info->{webserver}{hostname}
                  or die "Element not found in $test_info (keys: @k)";
            } catch {
                fail("No {webserver}{hostname} from $otter_test: $_");
                undef;
            };
            next unless $resp_host;

            $resp_host = FQDNify($resp_host, @all_srv) unless $resp_host =~ m{\.};

            # Tick off the ones we're looking for
            if (!exists $host{$resp_host}) {
                fail("Unexpected backend host $resp_host serving $otter_test");
            } elsif (!defined $host{$resp_host}) {
                # seen it, not interested
                diag("Saw $resp_host again - ignore");
            } else {
                ok(1, "Saw $resp_host serving $otter_test");
                $host{$resp_host} = undef;

                if (!grep { defined } values %host) {
                    diag "Finished early, on request $i of $tries";
                    last;
                }
            }

        } else {
            fail("Unexpected failure from $otter_test");
            diag join "\n",
              ($resp->request->as_string,
               $resp->status_line, $resp->headers_as_string, $resp->decoded_content);
        }
    }

    my @unseen = grep { defined $host{$_} } sort keys %host;
    fail("Did not see a response from backend $_ in $tries tries") foreach @unseen;

    return 0;
}


main();
