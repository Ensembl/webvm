#!/usr/bin/perl

## Move stuff from trunk to stage....
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

use HTML::Entities qw(encode_entities);

use English qw(-no_match_vars $PROGRAM_NAME $EVAL_ERROR);
use File::Basename qw(dirname basename);
use Cwd qw(abs_path);
use Data::Dumper;
use Carp qw(croak);
use Const::Fast qw(const);
use Getopt::Long qw(GetOptions);

# Define constants and data-structures

my $ROOT_PATH;
BEGIN { $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME))); }
use lib "$ROOT_PATH/lib";


use Pagesmith::Utils::Core;

my $support = Pagesmith::Utils::Core->new();

my $lr = $ROOT_PATH.'/logs';
## If it is www-.... then look for
$lr = "/www/tmp/$1/logs" if $ROOT_PATH =~ m{^\/www\/((\w+\/)?www-\w+)}mxs;
my $al = "$lr/diagnostic.log";
my $el = "$lr/error.log";

my $command_warn  = "grep warn] $el | sort | uniq -c | sort -n";
my $command_error = "grep error] $el | sort | uniq -c";

my @out;
my $rv = eval {
  @out = $support->read_from_process( $command_warn );
};
if( $EVAL_ERROR ) {
  printf "Unable to run: %s\n\n%s\n\n", $command_warn, $EVAL_ERROR;
} else {
  printf "%s\n-----------------------------------\n  %s\n\n", $command_warn, join "\n  ", @out;
}

my %H;
$rv = eval {
  @out = $support->read_from_process( $command_error );
  foreach( @out ) {
    s{\[\w{3}\s.*?\]\s*}{}mxs;
    s{\[client.*?\]s*}{}mxs;
    $H{$_}++;
  }
};
if( $EVAL_ERROR ) {
  printf "Unable to run: %s\n\n%s\n\n", $command_error, $EVAL_ERROR;
} else {
  printf "%s\n-----------------------------------\n  %s\n\n", $command_error, join "\n  ",
    sort keys %H;
}

