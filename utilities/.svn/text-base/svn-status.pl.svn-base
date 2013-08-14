#!/usr/bin/perl

## Keeps a serve up to date - BUT not using keep uptodate - basically runs svn up on each repository

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
use feature qw(switch);

use version qw(qv); our $VERSION = qv('0.1.0');

use HTML::Entities qw(encode_entities);

use Time::HiRes qw(time);
use English qw(-no_match_vars $PROGRAM_NAME $EVAL_ERROR $OUTPUT_AUTOFLUSH);
use Date::Format qw(time2str);
use File::Basename qw(dirname);
use Sys::Hostname::Long qw(hostname_long);
use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use Const::Fast qw(const);
use Getopt::Long qw(GetOptions);

const my $TO_MERGE       => 10;
const my $UPDATE_NO      => 50;
const my $DEF_SLEEP_TIME => 5;

my $ROOT_PATH;
BEGIN {
  $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME)));
}
use lib "$ROOT_PATH/lib";

use Pagesmith::Root;
use Pagesmith::Core qw(user_info);
use Pagesmith::ConfigHash qw(set_site_key);

my $DEBUG          = 0;
my $QUIET          = 0;

GetOptions(
  'verbose:+' => \$DEBUG,
  'quiet'     => \$QUIET,
);

my $start_time = time;

## no critic (BriefOpen RequireChecked)
my $repositories = _find_repositories();

my @files;
foreach my $repos    ( keys %{$repositories} ) {
  foreach my $branch ( keys %{$repositories->{$repos}} ) {
    foreach my $dir ( @{$repositories->{$repos}{$branch}} ) {
      push @files, [ "$repos$dir->{'path'}", $dir->{'directory'} ];
    }
  }
}

if( $DEBUG ) {
  print "FILES:\n",
    map { sprintf "\t%-40s - %s\n", @{$_}[1,0]; }
    sort { $a->[1] cmp $b->[1] }
    @files;
}

my $s = Pagesmith::Root->new;
my $user = user_info;

my @svn_command = (
  '/usr/bin/svn',
  '--config-option',
  "config:tunnels:ssh=ssh -i $user->{'home'}/.ssh/pagesmith/svn-ssh",
);

foreach (@files) {
  (my $fn = $_->[0]) =~ s{/}{-}mxsg;
  $fn = "$ROOT_PATH/tmp/svn/$fn.";
  my $path = "$ROOT_PATH/$_->[1]";
  my @commands = (
    [ 'update',   [@svn_command,qw(up -q --accept postpone)] ],
    [ 'status',   [@svn_command,qw(status -u)] ],
    [ 'stage',    [qw(/www/utilities/stage -d)] ],
    [ 'publish',  [qw(/www/utilities/publish -d)] ],
  );
  foreach my $cmd (@commands) {
    if( $DEBUG ) {
      print ">\t@{$cmd->[1]} $path\n";
    }
    my $r = $s->run_cmd( [@{$cmd->[1]}, $path] );
    my $contents = join "\n", @{$r->{'stdout'}}, qw();
    if( length $contents &&
        $contents !~ m{Repositories\sup\sto\sdate}mxs &&
        $contents !~ m{Cannot\sdo\sstage\sfor\srepository}mxs
    ) {
      my $flag = 'x';
      foreach my $line (@{$r->{'stdout'}}) {
        given( $flag ) {
          when( 'x' ) {
            $flag = q()  unless $line =~ m{\AX\s}mxs;
            $flag = q(t) if $line =~ m{\AStatus\sagainst\srevision}mxs;
          }
          when( 't' ) {
            $flag = $line =~ m{\APerforming\sstatus\son\sexternal\sitem\sat}mxs ? 'e' : q();
          }
          when( 'e' ) {
            $flag = $line =~ m{\AStatus\sagainst\srevision}mxs ? 't' : q();
          }
        }
      }
      $flag = q() unless $cmd->[0] eq 'status';
      if( $flag ne 't' ) {
        open my $o, '>', "$fn$cmd->[0]";
## no critic (ImplicitNewlines)
        printf {$o} '
------------------------------------------------------------------------
 %s for %s
------------------------------------------------------------------------

%s

------------------------------------------------------------------------
',
        $cmd->[0], $_->[0], $contents;
## use critic
        close $o;
        next;
      }
    }
    unlink "$fn$cmd->[0]" if -e "$fn$cmd->[0]";
    if( $DEBUG ) {
      print "<\t@{$cmd->[1]} $path\n";
    }
  }
}

sub _find_repositories {
## Search through the root directory (and sites subdirectory) to find
## any checkouts that we will be monitoring
#@return hashref of hashes of arrays - the keys being repository name and branch and the checkout directory
  my %repos;
  my $dh;
  my %paths = ( $ROOT_PATH => q(), "$ROOT_PATH/sites" => 'sites/' );
  foreach my $path (keys %paths) {
    next unless opendir $dh, $path;
    while( defined( my $dir = readdir $dh ) ) {
      next if $dir eq q(..) || $dir eq q(.);
      ## no critic (Filetest_f ComplexRegexes)
      if( -d "$path/$dir" && -d "$path/$dir/.svn" &&
          -f "$path/$dir/.svn/entries" &&
          open my $fh, q(<), "$path/$dir/.svn/entries" ) {
        while( my $line = <$fh> ) {
          chomp $line;
          if( $line =~ m{\Asvn[+]ssh://[^/]+/repos/svn/([^/]+(?:/[^/]+)?)/(trunk|live|staging)(.*)\Z}mxs ) {
            push @{ $repos{ $1 }{ $2 } }, { 'path' => $3, 'directory' => $paths{$path}.$dir };
            last;
          }
        }
        close $fh; ##no critic (RequireChecked)
      }
      ## use critic
    }
  }
  return \%repos;
}


