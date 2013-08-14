#!/usr/bin/perl

## Usage          : flush-access.pl ?
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

use Const::Fast qw(const);

const my $LINE_LENGTH => 78;

use Cwd            qw(abs_path);
use English        qw(-no_match_vars $EVAL_ERROR $PROGRAM_NAME $INPUT_RECORD_SEPARATOR);
use File::Basename qw(dirname);
use Data::Dumper;

my $ROOT_PATH;

BEGIN {
  $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME)));
}

use lib "$ROOT_PATH/lib";

use Pagesmith::ConfigHash qw(set_site_key);
use Pagesmith::Utils::SVN::Config;
# force flush!

set_site_key( 'no-site' );

my $rv = eval {
  my $conf = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH, 'IPC', 1 );
  print Data::Dumper->new( [ $conf ], [ 'conf' ] )->Sortkeys(1)->Indent(1)->Terse(1)->Dump() if $ARGV[0]; ## no critic (CheckedSyscalls)
};
printf "%s\n" , $EVAL_ERROR || 'Successfully written';
## We need to flush the memcached versions on the "editing servers"...

