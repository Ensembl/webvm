#!/usr/bin/perl

## Tail error/access logs
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

use English qw(-no_match_vars $PROGRAM_NAME $ERRNO);

use Getopt::Long qw(GetOptions);
use File::Basename qw(dirname basename);
use Cwd qw(abs_path);
use POSIX qw(strftime floor);
use English qw(-no_match_vars $ERRNO);

use Const::Fast qw(const);
const my $MINUTE   => 60;
const my $INTERVAL => 5;
const my $MAXDUR   => 3;
const my $TOTDUR   => 4;
const my $STDINF   => -1;

my $path    = dirname(dirname(abs_path($PROGRAM_NAME)));
my $system  = basename($path);

my $lr = $path.'/logs';
## If it is www-.... then look for
$lr = "/www/tmp/$1/logs" if $path =~ m{^\/www\/(([-\w]+\/)?www-\w+)}mxs;

my $al = "$lr/diagnostic.log";
my $interval = $INTERVAL;
my $help     = 0;

GetOptions(
  'file=s'     => \$al,
  'interval=i' => \$interval,
  'help'       => \$help,
);

## no critic (ImplicitNewlines RequireCarping)
die '
------------------------------------------------------------------------
Usage:
  utilities/count-log.pl
    [-f|--file]
    [-i|--interval]
    [-h|--help]

Options:
  -f, --file      : File to parse
  -i, --interval  : Interval in minutes to report stats
  -h, --help      : print this help message

------------------------------------------------------------------------
' if $help;
## use critic;

$interval *= $MINUTE;

my $events;

my $fh;
my $flag = 0;

## no critic (BriefOpen)
if( $al eq q(-) ) {
  $fh = \*STDIN;
  $flag = $STDINF;
} else {
  $flag = open $fh, q(<), $al;
}
if( $flag ) {
  while(<$fh>) {
    if( m{"[ ](\d+[.]\d+)/(\d+[.]\d+)[ ]\[}mxs ) {
      my $dur = $2 - $1;
      push @{$events->{$1}{'s'}}, $dur;
      push @{$events->{$2}{'e'}}, $dur;
    }
  }
  if( $flag > 0 ) {
    close $fh; ## no critic (RequireChecked)
  }
} else {
  die "COULD NOT OPEN FILE '$al' - $ERRNO\n";
}
## use critic

my @event_times = sort { $a <=> $b } keys %{$events};
my %intervals;
my $n_req   = 0;
my $max_dur = 0;
my $max_req = 0;
my $max_time = 0;
my $max_dur_time = 0;
my $tot_st  = 0;
my $tot_dur = 0;
my $tot_fi  = 0;

parse_events();
write_output();
sub parse_events {
foreach (@event_times) {
  my $st = exists $events->{$_}{'s'} ? scalar @{$events->{$_}{'s'}} : 0;
  my $fi = exists $events->{$_}{'e'} ? scalar @{$events->{$_}{'e'}} : 0;
  $n_req += $st - $fi;
  $tot_st += $st;
  $tot_fi += $fi;
  my @time = localtime $_;
  my $s_past_hour = $time[0] + $MINUTE * ( $time[1] + $time[2] * $MINUTE);
  my $s_block     = floor( $s_past_hour / $interval ) * $interval;
  $time[0] = $s_block % $MINUTE;
  $time[1] = ( ($s_block - $time[0])/$MINUTE ) % $MINUTE;
  $time[2] = ($s_block - $time[0] - $time[1]*$MINUTE)/$MINUTE/$MINUTE;
  my $time = strftime( q(%Y-%m-%d %H:%M:%S), @time );

  if( $n_req > $max_req ) {
    $max_req  = $n_req;
    $max_time = $_;
  }
  if( exists $intervals{$time} ) {
    $intervals{$time}[0] = $n_req if $n_req > $intervals{$time}[0];
    $intervals{$time}[1] += $st;
    $intervals{$time}[2] += $fi;
  } else {
    $intervals{$time} = [ $n_req, $st, $fi, 0, 0 ];
  }
  foreach my $dur ( @{$events->{$_}{'s'}||[]} ) {
    $max_dur = $dur if $dur > $max_dur;
    $tot_dur += $dur;
    $intervals{$time}[$MAXDUR] =$dur if $dur > $intervals{$time}[$MAXDUR];
    $intervals{$time}[$TOTDUR]+=$dur;
  }
}
  return;
}

sub write_output {
foreach (sort keys %intervals) {
  my $diff = $intervals{$_}[1]-$intervals{$_}[2];
  printf "%s\t%5d\t%5d\t%5d\t%12.5f\t%12.5f\t\t%s\n",
    $_,
    @{$intervals{$_}}[0,1,2,$MAXDUR],
    $intervals{$_}[1] ? $intervals{$_}[$TOTDUR]/$intervals{$_}[1] : 0,
    $diff ? sprintf '%s%d', $diff < 0 ? q(-):q(+), abs $diff : q();
}

printf {*STDERR} "\nMax requests:   %8d         \@ %s", $max_req, strftime( q(%Y-%m-%d %H:%M:%S), localtime $max_time );
if( $tot_st > 0 ) {
  printf {*STDERR} "\nTotal requests: %8d         (%8d)\nTotal duration:   %12.5f\nAverage duration: %12.5f",
    $tot_st, $tot_fi, $tot_dur, $tot_dur/$tot_st;
}
print {*STDERR} "\n\n"; ## no critic (RequireChecked)
  return;
}
