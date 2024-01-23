#! /usr/bin/perl -T
# Copyright [2018-2024] EMBL-European Bioinformatics Institute
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

use Test::HTtapTP ':cors_ok';
use Test::More;

use URI;

use Bio::Otter::Server::Config; # to find the designations
use Otter::WebNodes; # to find self
use Otter::TestUA 'make_ua';


my $version;
my $ua;

sub main {
    plan tests => 2;
    my @version = Bio::Otter::Server::Config->extant_versions();
    cmp_ok(scalar @version,
           '>', 1, # live & dev
           'some Otter Server versions');

    $ua = make_ua();

    subtest "All Otters" => sub {
        plan tests => scalar @version;
        foreach my $major (@version) {
            $version = $major;
            subtest "Otter v$version" => \&otter_server_tt;
        }
    };
    return 0;
}

sub otter_server_tt {
    my @part = qw( test get_sequencesets?client=OtterServer/present.t&dataset=human );
    push @part,  $version < 73 ? 'get_otter_config' : 'get_config?key=otter_config';
    plan tests => scalar @part;

    my $me = Otter::WebNodes->new_cgi;
    my $is_sandbox = $me->type eq 'sandbox'; # causes leniency
    my $server_here = $me->base_uri;
    my $otter = URI->new_abs("/cgi-bin/otter/$version", $server_here);

    foreach my $part (@part) {
        my $uri = "$otter/$part";
        my $resp = $ua->get($uri);
        if ($part eq 'test' && $resp->code eq '410') {
            local $TODO;
            $TODO = $is_sandbox ? 'this is sandbox' : undef;
            fail("410 Gone - $uri");
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
