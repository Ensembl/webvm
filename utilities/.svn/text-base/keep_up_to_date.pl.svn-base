#!/usr/bin/perl

## Keep server up to date
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

use Mail::Mailer;
use Time::HiRes qw(time);
use English qw(-no_match_vars $UID $PROGRAM_NAME $EVAL_ERROR $OUTPUT_AUTOFLUSH);
use Date::Format qw(time2str);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use Const::Fast qw(const);
use Getopt::Long qw(GetOptions);
use Sys::Hostname qw(hostname);
use List::MoreUtils qw(uniq);
use IO::Handle;
use Socket qw(inet_ntoa);

const my $TO_MERGE       => 10;
const my $UPDATE_NO      => 50;
const my $DEF_SLEEP_TIME => 5;
const my $DEF_CHECK_RUNS => 100;
const my $MAX_BLOCK_MULT => 30;

my $ROOT_PATH;
BEGIN {
  $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME)));
}
use lib "$ROOT_PATH/lib";

use Pagesmith::Adaptor::PubQueue;
use Pagesmith::Utils::SVN::Support;
use Pagesmith::ConfigHash qw(set_site_key);

my $SLEEP_TIME     = $DEF_SLEEP_TIME;
my $MAX_RUNS       = 0;  ## Run forever...
my $CHECK_RUNS     = $DEF_CHECK_RUNS;  ## Run forever...
my $DEBUG          = 0;
my $QUIET          = 0;
my $OWNER          = q();
my $OUT_DIR        = "$ROOT_PATH/logs";
( my $tmp_dir = $OUT_DIR ) =~ s{\A/www/}{/www/tmp/}mxs;
$OUT_DIR = $tmp_dir if -e $tmp_dir;

my $LOG_FILE;
my $ERR_FILE;
my $BLK_FILE;
my $FLUSH = 0;

GetOptions(
  'owner'     => \$OWNER,
  'verbose:+' => \$DEBUG,
  'quiet'     => \$QUIET,
  'sleep=f'   => \$SLEEP_TIME,
  'dir:s'     => \$OUT_DIR,
  'block:s'   => \$BLK_FILE,
  'logfile:s' => \$LOG_FILE,
  'errorlog:s'=> \$ERR_FILE,
  'runs:i'    => \$MAX_RUNS,
  'check:i'   => \$CHECK_RUNS,
  'flush'     => \$FLUSH,
);


_config();
my $start_time = time;

set_site_key( 'no-site' ); ## This is so we get the dev pubqueue!

my $adap    = Pagesmith::Adaptor::PubQueue->new;
my $support = Pagesmith::Utils::SVN::Support->new;

my $host = hostname() || 'localhost';
   $host = inet_ntoa( scalar gethostbyname $host );

my $checkout_id = $adap->set_checkout( $host, $ROOT_PATH );

my $run_number = 1;

$OUTPUT_AUTOFLUSH = 1;

my $efh;
my $lfh;
_open_files();

my $time = gmtime;
printf {$efh}  "\n====================================\n\n  RESTARTED AT %s\n\n====================================\n\n", $time unless $QUIET;

my $blk_counter = 0;

my $repositories = _find_repositories();

while( 1 ) {
  next if _check_block();
  my $loop_start_time = time;

  unless( $run_number % $CHECK_RUNS ) {
    $repositories = _find_repositories();
  }
  my $l_time = gmtime;
  printf {$efh} "## RUN: %6d; time: %s\n", $run_number, $l_time if $DEBUG > 1;

  $adap->touch_checkout( );

  ## We need to do some additional code in here which will pick up changes that are in
  ## externals directives....

  foreach my $repos ( sort keys %{$repositories} ) {
    my $repos_id = $adap->set_repository( $repos );
    foreach my $branch ( sort keys %{$repositories->{$repos}} ) {
      my $branch_start_time = time;
      $adap->set_branch( $branch );
      $adap->touch_checkout_repository();
      my $outstanding = $adap->outstanding_updates();
      next unless @{$outstanding};
      ## Get a list of paths!
      my $success = 1;
      my @paths = uniq sort map { "/$_->{'path'}" } @{$outstanding};
      my $count_t = 0;
      foreach my $sub_directory ( sort keys %{$repositories->{$repos}{$branch}} ) {
        my $revisions = {};
        my $tree = _get_tree_from_paths( $sub_directory, \@paths );
        _prune( $tree );
        my @minimal_paths = _get_minimal_paths( $sub_directory, $tree );
        my $count = @minimal_paths * @{$repositories->{$repos}{$branch}{$sub_directory}};
        printf {$efh} "%s\n", Dumper ( \@minimal_paths ) if $DEBUG > 2;
        next unless $count;
        $count_t += $count;
        printf {$efh} "%s\n", Dumper( $repositories->{$repos}{$branch} ) if $DEBUG > 2;
        ## Now we have to perform the svn updates....
        $success *= _update_files( $support, $sub_directory, $repositories->{$repos}{$branch}{$sub_directory}, @minimal_paths);
      }
      $adap->touch_updates( [ map { $_->{'id'} } @{$outstanding} ]) if $success;

      my $r_time = gmtime;
      printf {$lfh} "success: %d time: %s; run: %7d;   updates: %5d;   time: %8.3f;   repos: %-30s;   branch: %-10s;\n",
        $success, $r_time, $run_number, $count_t, time-$branch_start_time, $repos, $branch if $DEBUG;
      ## and flag them as done in the database for this checkout!
    }
  }
  $adap->cleanup_checkout( );
  printf {$efh} "## RUN: %6d; time: %s; duration: %8.4f\n", $run_number, $l_time, time - $loop_start_time if $DEBUG;
  $run_number++;
  last if $MAX_RUNS && $run_number > $MAX_RUNS;
  sleep $SLEEP_TIME;
}

sub _get_minimal_paths {
  my( $dir, $tree ) = @_;
  return uniq sort
    map { substr $_, 1 }
    map { (length $_ < length $dir) ? "/$dir" : $_ }
    map { substr $_, 1 }
    _extract_paths( $tree, q() ); ## Extract the paths
}
sub _get_tree_from_paths {
  my( $dir, $paths ) = @_;
  my $tree = {};
  foreach my $path ( grep {
    ( $_   eq substr $dir, 0, length $_   ) ||
    ( $dir eq substr $_,   0, length $dir )
  } @{$paths} ) {
    my @parts = split m{/}mxs, "-$path";
    my $t = $tree;
    my $p;
    foreach( @parts ) {
      $t->{$_} ||= [ 0, {} ];
      $p = $t->{$_};
      $t = $t->{$_}[1];
    }
    $p->[0] = 1;
  }
  return $tree;
}

sub _update_files {
## Perform the update commands
#@return (boolean) 1 if all updates succeed
  my( $l_support, $sub_dir, $PATHS, @minimal_paths ) = @_;
  my $ui = $l_support->get_user_info;
  foreach my $dirh ( @{$PATHS} ) {
    my $path = $dirh->{'directory'};
    my $root_path = substr $path, 0, 1 + (length $path) - (length $sub_dir);
    my $dir  = $dirh->{'directory'};
    my @paths = map { "$root_path$_" } @minimal_paths;
    while( my @block = splice @paths, 0, $UPDATE_NO ) {
      my $command = sprintf q(SVN_AUTH_SOCK="" /usr/bin/svn --config-option config:tunnels:ssh=ssh\ -i\ %s/.ssh/pagesmith/svn-ssh up %s),
        $ui->{'home'},  join q( ), @block;
## use critic
      my $rv = eval {
        $l_support->read_from_process( $command );
      };
      if( $EVAL_ERROR ) {
        printf {$efh} "COMMAND: %s\n", $command;
        printf {$efh} "ERROR:   %s\n", $EVAL_ERROR;
        if( $EVAL_ERROR =~ m{Conflict\s+discovered}mxs ) {
          _force_block( 'Conflict discovered', $EVAL_ERROR );
        }
        return 0;
      }
      printf {$lfh} $command."\n" unless $QUIET;
    }
  }
  return 1;
}

sub _extract_paths {
## Convert directory tree back into an array of paths
#@ array of directory paths
  my( $tree, $path ) = @_;
  my @ret;
  foreach (keys %{$tree}) {
    if( $tree->{$_}[0] ) {
      push @ret, "$path/$_";
    } else {
      push @ret, _extract_paths( $tree->{$_}[1], "$path/$_" );
    }
  }
  return @ret;
}

sub _prune {
## Reduce the tree
## If a node is in the original file list its [0] value will be 1
##   therefore can ignore elements in tree (will update directory - don't need to update sub-directories/files)
## If the directory contains more than "TO_MERGE" elements then we also reduce the update to that directory
##   this reduces the complexity of the update command!
#@return nothing
  my $tree = shift;
  foreach ( keys %{$tree} ) {
    if($tree->{$_}[0] || scalar keys %{$tree->{$_}[1]} >= $TO_MERGE ) {
      $tree->{$_}[0] =1;
      $tree->{$_}[1] ={};
    } else {
      _prune( $tree->{$_}[1] );
    }
  }
  return;
}


sub _find_repositories {
## Search through the root directory (and sites subdirectory) to find
## any checkouts that we will be monitoring
#@return hashref of hashes of arrays - the keys being repository name and branch and the checkout directory
  my $repos = {};
  my $ui = $support->get_user_info;
  my $command = sprintf q(/usr/bin/svn --config-option config:tunnels:ssh=ssh\ -i\ %s/.ssh/pagesmith/svn-ssh info %s %s/sites/*),
    $ui->{'home'}, $ROOT_PATH, $ROOT_PATH;
  my @out = eval {  $support->read_from_process( $command ); };
  my @lines = grep { m{(URL|Path):}mxsg } @out;
  my $dir;
  foreach my $repos_line ( @lines ) {
    my( $type, $val ) = split m{:\s+}mxs, $repos_line , 2;
    if( $type eq 'Path' ) {
      $dir = $val;
    } else {
      next unless defined $dir;
      my $details = _parse_svn_url($val);
      unless( $details ) {
        $dir = undef;
        next;
      }
      push @{ $repos->{ $details->{'repos'} }{ $details->{'branch'} }{ "$details->{'path'}/" } }, {
        'directory' => $dir,
        'url'       => $details->{'url'},
        'root'      => $details->{'root'},
      };

      my $get_command = sprintf q(/usr/bin/svn --config-option config:tunnels:ssh=ssh\ -i\ %s/.ssh/pagesmith/svn-ssh propget --recursive svn:externals %s),
        $ui->{'home'}, $dir;
      my @ex_lines = eval { $support->read_from_process( $get_command ); };
      my $path;
      my $res = {};
      foreach ( @ex_lines ) {
        unless( $_ ) {
          $path = undef;
          next;
        }
        unless( $path ) {
          $path = $1 if s{\A(\S+)\s+-\s+}{}mxs;
        }
        next unless $path;
        if( m{(\S+)\s+(.*)}mxs ) {
          my( $subdir, $url ) = ($1,$2);
          my $ext_details = _parse_svn_url($url);
          next unless $ext_details;
          push @{ $repos->{ $ext_details->{'repos'} }{ $ext_details->{'branch'} }{ "$ext_details->{'path'}/" } }, {
            'directory' => "$path/$subdir",
            'url'       => $ext_details->{'url'},
            'root'      => $ext_details->{'root'},
          };
        }
      }
      $dir = undef;
    }
  }
  _debug_dump( $repos )  if $DEBUG > 1;
  return $repos;
}

sub _parse_svn_url {
  my $url = shift;
  my( $root, $repos, $branch, $path ) = split m{/([^/]+)/(trunk|staging|live)}mxs, $url;
  $path ||= q();
  return {} unless $branch;
  return {
    'url'    => $url,
    'repos'  => $repos,
    'root'   => $root,
    'branch' => $branch,
    'path'   => $path,
  };
}

sub _force_block {
  my( $subject, $body ) = @_;
  return if -e $BLK_FILE;
  if( open my $fh, q(>), $BLK_FILE ) {
    ## This is where we need to perform a send mail...
    my $flag = close $fh;
    my $mailfh = Mail::Mailer->new;
    $mailfh->open({
      'Importance' => 'High',
      'To'         => $OWNER,
      'From'       => $OWNER,
      'Subject'    => sprintf 'KEEP UP TO DATE: %s (%s)', $subject, hostname,
    });
    ## no critic (ImplicitNewlines)
    printf {$mailfh} '
------------------------------------------------------------------------

  keep_up_to_date on %s has placed a block file because of an error

------------------------------------------------------------------------

  Subject:    %s
  Host:       %s
  Time:       %s
  User:       %s
  Binary:     %s

  Log file:   %s
  Error log:  %s
  Block file: %s

------------------------------------------------------------------------

%s

------------------------------------------------------------------------
',
    hostname, $subject,
    hostname, scalar gmtime, scalar getpwuid $UID,
    abs_path($PROGRAM_NAME),
    $LOG_FILE, $ERR_FILE, $BLK_FILE,
    $body;
    ## use critic
    $mailfh->close;
    return $flag;
  }
  return;
}

sub _check_block {
  if( -e $BLK_FILE ) {
    my $blk_time = scalar gmtime;
    printf {$lfh}  "\nBLOCKED AT %s BY %s\n", $blk_time, $BLK_FILE;
    $blk_counter++;
    $blk_counter = $MAX_BLOCK_MULT if $blk_counter > $MAX_BLOCK_MULT;
    sleep $SLEEP_TIME * $blk_counter;
    next;
  } else {
    $blk_counter = 0;
  }
  return;
}

sub _debug_dump {
  my $repos = shift;
  foreach my $repo ( sort keys %{$repos} ) {
    foreach my $branch ( sort keys %{$repos->{$repo}} ) {
      printf {$efh} "Repos: %-30s; Branch: %-10s.\n", $repo, $branch;
    }
  }
  return;
}

sub _open_files {
## no critic (BriefOpen RequireChecked)
  my $open_type = $FLUSH ? q(>) : q(>>); ## Flush then we will start a new file!
  unless( open $efh, $open_type, $ERR_FILE ) {
    $efh->autoflush(1);
    die "CANNOT CREATE Error log file: $ERR_FILE\n";
  }
  unless( open $lfh, $open_type, $LOG_FILE ) {
    $lfh->autoflush(1);
    die "CANNOT CREATE Log file: $LOG_FILE\n";
  }
## use critic
}

sub _config {
  $LOG_FILE ||= 'svn-update.log';
  $ERR_FILE ||= 'svn-update.err';
  $BLK_FILE ||= 'svn-update.block';

  $OWNER    ||= scalar getpwuid $UID;

  $LOG_FILE = $OUT_DIR.q(/).$LOG_FILE unless $LOG_FILE =~ m{/}mxs;
  $ERR_FILE = $OUT_DIR.q(/).$ERR_FILE unless $ERR_FILE =~ m{/}mxs;
  $BLK_FILE = $OUT_DIR.q(/).$BLK_FILE unless $BLK_FILE =~ m{/}mxs;
  return;
}

