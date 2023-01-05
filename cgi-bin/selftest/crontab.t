#! /usr/bin/perl -T
# Copyright [2018-2023] EMBL-European Bioinformatics Institute
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
use Otter::Paths qw( HTtapTP-0.04 );
use Otter::WebCrontab qw( invent_crontab );

use Test::HTtapTP ':cors_ok';
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
