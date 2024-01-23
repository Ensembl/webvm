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
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More tests => 2;

ok(1, "The only reason for this test to fail is a transport error");
diag("Or maybe a library error");

ok(5, "I would offer a TODO-fail test here, but tap-parser.js does not understand TODO marks"); # XXX: new version available by now?  or fix it?
#local $TODO = "Make everything work";
#fail("This test should not be necessary");
