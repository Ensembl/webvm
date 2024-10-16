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


## Checks that the server is "open" - if a file /www/www-svn/maint exists it isn't
##
## Usage          : check-message.pl {repository name} {transaction-id}
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2012-07-16 16:48:14 +0100 (Mon, 16 Jul 2012) $
## Revision       : $Revision: 1 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/svn/start-commit.d/server-down.pl $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Cwd            qw(abs_path);
use English        qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);

my $ROOT_PATH;

BEGIN {
  $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME)))));
}

use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::SVN::Support;

my $support = Pagesmith::Utils::SVN::Support->new();

## Exit 0 unless the file /www/www-svn/maint exists

exit 0 unless -e "$ROOT_PATH/maint";

## Otherwise send an error and cancel the commit

$support->send_message(
 'The stage/publish mechanism on this SVN repository is currently disabled - please try again later' )->clean_up();

exit 1;  # Commit is cancelled in this case!
