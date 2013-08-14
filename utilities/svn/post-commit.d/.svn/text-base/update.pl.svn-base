#!/usr/bin/perl

## Updates "dev"
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

use Cwd qw(abs_path);
use English qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);
use Const::Fast qw(const);

my $ROOT_PATH;
BEGIN {
  $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME)))));
}
use lib "$ROOT_PATH/lib";

const my $AT_A_TIME => 10;

use Pagesmith::Utils::SVN::Support;
use Pagesmith::Utils::SVN::Config;
use Pagesmith::ConfigHash qw(set_site_key);

set_site_key( 'no-site' );

use Pagesmith::Adaptor::PubQueue;

exit 1 unless @ARGV == 2;               ## Two parameters
my( $repos, $rev ) = @ARGV;             ## Repository name and revision

my $support = Pagesmith::Utils::SVN::Support->new;
   $support->turn_on_debug->log_revision( $rev );
   $support->write_log( "Starting to update server - repository $repos" );
my $config  = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
   $support->write_log( 'Read in config' );

my( $author, $datastamp, $len, @msg )  = $support->svnlook( 'info', $repos, '-r', $rev );

my $user    = Pagesmith::Utils::SVN::Support->get_user_info( $author );

exit 0 unless $config;                                    ## Could not parse file so returned UNDEF!
exit 0 unless $config->set_repos( $repos );               ## We have not configured this repository - so we don't need to send anything
exit 1 unless $config->set_user( $user->{'username'} );   ## User is not valid! shouldn't happen svn ci should have failed

$support->write_log( 'Initialiased repos and user' );

$support->write_log( 'About to do svnlook' );
my @changed = $support->svnlook( 'changed', $repos, '-r', $rev );



my $branch     = q();
my $other_user = q();

my $msg = join "\n", @msg;

$support->write_log( "USER: $user->{'username'}\nChanged[0]: $changed[0]\nMSG: $msg\n");

if(
  $user->{'username'}           eq 'www-core' &&
  $changed[0] =~ m{\A..\s\s(live|staging)/}mxs &&
  $msg        =~ m{\[([-\w\,]+)]\s(\w+)\son\s(stage|publish)\Z}mxs
) {
  $support->write_log( "USER SET TO $1...." );
  $user       = Pagesmith::Utils::SVN::Support->get_user_info( $1 );
  exit 1 unless $config->set_user( $user->{'username'} );
}

$support->write_log( 'Finished svnlook' );
exit 1 unless $author eq $user->{'username'} || $author eq 'www-core';

my $files = {};

my $pqh = Pagesmith::Adaptor::PubQueue->new();

## We need to change the user here!
## From www-core to the user in the commit message if not on trunk

$pqh->set_user( $user->{'username'}, $user->{'name'} );
my ($rep) = $repos =~ m{.*/([^/]+)\Z}mxs;
$pqh->set_repository( $rep );
$pqh->set_revision( $rev );

$support->push_changes( $pqh, \@changed );

## We need to SSH onto the development box - this requires use of the
## special svn key.
## For users with their own ssh-key recognised by the development box
## (this will mainly be webteam members) we need to make sure it doesn't
## try and use their key agent's key (otherwise the script isn't restricted
## correctly and commands aren't logged!
## To do this we need to remove the SSH_AUTH_SOCK environment variable, and
## restore it after the command has been run...

$support->clean_log;
