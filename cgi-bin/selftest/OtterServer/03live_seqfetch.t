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
use Digest::SHA 'sha1_hex';

use Bio::Otter::Server::Config; # to find the designations
use Otter::WebNodes; # to find self
use Otter::TestUA 'make_ua';


sub main {
    # list of expected [ accession, sha1sum, type ]
    my @fetch = map {[ split /\s+/, $_ ]}
      grep { /\S/ && ! /^\s*#/ } <DATA>;

    plan tests => 1 + 2 * @fetch;

    my $desig = Bio::Otter::Server::Config->designations();
    my ($version) = $desig->{live} =~ m{^(\d{2,4})\.};
    ok($version, "got live version number ($$desig{live})") || die;
    diag "Testing just Otter Server v$version";

    my $me = Otter::WebNodes->new_cgi;
    my $server_here = $me->base_uri;
    my $otter = URI->new_abs("/cgi-bin/otter/$version", $server_here);

    foreach my $fetch (@fetch) {
        my ($acc, $want_seq_sha1, $want_type) = @$fetch;

        my $got_seq = do_req("$otter/pfetch?request=$acc");
        my $got_seq_sha1;
        if (!defined $got_seq || $got_seq eq '') {
            $got_seq_sha1 = '(nil)';
        } elsif ($got_seq eq "no match\n") {
            $got_seq_sha1 =  'no_match';
        } else {
            $got_seq_sha1 = sha1_hex($got_seq);
        }
        is($got_seq_sha1, $want_seq_sha1, "pfetch $acc") || diag $got_seq;

        my $got_acc_type = do_req("$otter/get_accession_types?accessions=$acc");
        my $got_type = ($got_acc_type =~ /\S/
                        ? join ':', (split /\s+/, $got_acc_type)[1,3]
                        : '(nil)');
        is($got_type, $want_type, "get_accession_types $acc") || diag $got_acc_type;
    }
}

my $ua;
sub do_req {
    my ($uri) = @_;
    $ua ||= make_ua();
    my $resp = $ua->get($uri);
    return $resp->decoded_content if $resp->is_success;
    return join "\n",
      ($resp->request->as_string,
       $resp->status_line, $resp->headers_as_string, $resp->decoded_content);
}

main();

__DATA__
# constructed by hand, expecting it to never change
NM_001142769.1  54a8e190de3507a19b981f9f86880c1440df29ea (nil)
M87879.1        1c369790e301ac7a3f7b4d097d025f9d12176da9 cDNA:EMBL
BC104468.1      37284b6cf6d4e32babbe678cb52e26184e81047a cDNA:EMBL
Q6ZTW0.2        d613b255d2ff717b4848f2451400c529d12cd358 Protein:Swissprot
SRS000012       no_match                                 SRA:SRA_Sample
