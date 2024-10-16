#!/usr/bin/perl
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


## Sends an email on every commit!
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2012-07-16 16:48:14 +0100 (Mon, 16 Jul 2012) $
## Revision       : $Revision: 1 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/svn/start-commit.d/check-user.pl $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

# The following libraries and block needed to get paths
# sorted out for lib to get the Pagesmith support modules
use Cwd qw(abs_path);
use English qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);

my $ROOT_PATH;
BEGIN { $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME))))); }
use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::SVN::Support;
use Pagesmith::Utils::SVN::Config;

exit 1 if @ARGV <= 1; ## EXIT EARLY IF PARAMETERS INCORRECT!
my( $repos, $user ) = @ARGV;

my $config  = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
my $support = Pagesmith::Utils::SVN::Support->new;

## Not configured correctly!
exit 0 unless $config;
## We are not watching this repository - so we don't need to send anything
exit 0 unless $config->set_repos( $repos );
## User can commit to repository
exit 0 if     $config->set_user( $user );

$support->send_message( "User '%s' unable to commit to this repository '%s'\n", $user, $repos )->clean_up();
exit 1;


