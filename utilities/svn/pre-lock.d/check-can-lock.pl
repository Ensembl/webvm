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


## Check that the user can lock the file...
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2013-01-21 10:51:22 +0000 (Mon, 21 Jan 2013) $
## Revision       : $Revision: 473 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/svn/pre-lock.d/check-can-lock.pl $

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

exit 1 if @ARGV <= 2; ## EXIT EARLY IF PARAMETERS INCORRECT!
my( $repos, $path, $user ) = @ARGV;

my $config  = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
my $support = Pagesmith::Utils::SVN::Support->new;

exit 0 unless $config;
## We are not watching this repository - so we don't need to send anything
exit 0 unless $config->set_repos( $repos );
## User can commit to repository

unless( $config->set_user( $user ) ) {
  $support->send_message( 'User "%s" unable to update repository "%s"', $user, $repos )->clean_up();
  ## User can't perform any action on repository...
  exit 1;
}

unless( $config->can_perform( $path, 'lock' ) ) {
  $support->send_message( 'User "%s" unable to lock this path "%s" in repository "%s"', $user, $path, $repos )->clean_up();
  ## User can't lock this path!
  exit 1;
}

exit 0 if $config->can_perform( $path, 'break' ); ## Can break lock!

my(@lines) = $support->svnlook( 'lock', $repos, $path );

exit 0 unless @lines;

my $lock_info = {};
if( @lines ) {
  while ( my $line = shift @lines ) {
    chomp $line;
    next unless $line =~ m{:}mxs;
    my( $key,$value ) = split m{:\s*}mxs, $line;

    if( $key =~ m{\AComment\s[(](\d+)\slines?[)]\Z}mxs ) {
      my $comment_lines = $1;
      if( $comment_lines ) {
        $lock_info->{'comment'} = join qq(\n  ), splice @lines, 0, $comment_lines;
      } else {
        $lock_info->{'comment'} = q('no message');
      }
    } else {
      $lock_info->{$key} = $value;
    }
  }
}
$support->send_message(
  "You cannot break the lock on this file\n\nUser '%s' has lock on this file with comment:\n  %s",
  $lock_info->{'Owner'}, $lock_info->{'comment'} )->clean_up();


exit 1;
