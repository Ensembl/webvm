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
## Last modified  : $Date: 2013-05-22 21:51:14 +0100 (Wed, 22 May 2013) $
## Revision       : $Revision: 708 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/svn/post-commit.d/send-emails.pl $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Const::Fast qw(const);

const my $WRAP_COLUMNS  => 72;
const my $DEFAULT_EMAIL => 'microsite-commits@sanger.ac.uk';

use Carp qw(croak);
use Cwd qw(abs_path);
use English qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);
use Mail::Mailer;
use Text::Wrap qw(fill $columns);

my $ROOT_PATH;
BEGIN {
  ## Get to root path so we can load in the Pagesmith utilities...
  $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME)))));
}
use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::SVN::Support;
use Pagesmith::Utils::SVN::Config;

exit 1 unless @ARGV == 2; ## EXIT EARLY IF PARAMETERS INCORRECT!
my( $repos, $rev ) = @ARGV;

my $config  = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
## Not configured correctly!
exit 0 unless $config;
## We are not watching this repository - so we don't need to send anything
exit 0 unless $config->set_repos( $repos );

my $support = Pagesmith::Utils::SVN::Support->new;

my( $name, $datestamp, $len, @msg )  = $support->svnlook( 'info', $repos, '-r', $rev );

my $user = $support->get_user_info( $name );

exit 1 unless $user;

my @changed = $support->svnlook( 'changed', $repos, '-r', $rev );

my $to_email = $config->info( 'commit_emails' ) || [ $DEFAULT_EMAIL ];


my $mailer = Mail::Mailer->new;

my $subject = q();
if( $config->is_site ) {
  $subject = sprintf 'Commit to repository %s [Site: %s, rev: %d] by %s <%s>',
    $config->repos, $config->key, $rev, $user->{'name'}, "$user->{'username'}\@sanger.ac.uk";
} else {
  $subject = sprintf 'Commit to repository %s [Libraries: %s, rev: %d] by %s <%s>',
    $config->repos, $config->key, $rev, $user->{'name'}, "$user->{'username'}\@sanger.ac.uk";
}

$mailer->open({
  'To'       => $to_email,
  'From'     => "$name\@sanger.ac.uk",
  'Subject'  => $subject,
  'X-Mailer' => 'svn-commit',
});

my $files   = join "\n  ", @changed;
my $message = join "\n  ", @msg;

$columns = $WRAP_COLUMNS;

printf {$mailer} "The following files in %s have been changed:\n  %s\n\nThe commit message was:\n%s",
  $repos,
  $files,
  fill( q(    ),q(    ),$message );

$mailer->close;

exit 0;
