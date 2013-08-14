#!/usr/bin/perl

## Checks that the server is "open" - if a file /www/www-svn/maint exists it isn't
##
## Usage          : check-message.pl {repository name} {transaction-id}
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

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
