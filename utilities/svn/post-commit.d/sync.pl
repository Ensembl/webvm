#!/usr/bin/perl

## Updates "dev"
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2010-09-08 11:08:42 +0100 (Wed, 08 Sep 2010) $
## Revision       : $Revision: 196 $
## Repository URL : $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/www-shared-content/trunk/lib/Pagesmith/CriticSupport.pm $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Cwd qw(abs_path);
use English qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);
use Const::Fast qw(const);

exit 0 if @ARGV < 0;

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

exit 1 unless @ARGV == 2;               ## Two parameters

my( $repos, $rev ) = @ARGV;             ## Repository name and revision

my $support = Pagesmith::Utils::SVN::Support->new;
my $config  = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
my $user    = Pagesmith::Utils::SVN::Support->get_user_info;

exit 0 unless $config;
exit 0 unless $config->set_repos( $repos );
exit 1 unless $config->set_user( $user->{'username'} );

my $mirrors = $config->info('mirrors');

exit 0 unless $mirrors;
foreach my $mirror_config ( @{$mirrors} ) {
##use Data::Dumper; open FH,'>',"/tmp/svn-$$"; print FH Dumper( $config->info('mirrors') ); close FH;
  $support->read_from_process( qw(/usr/bin/svnsync synchronize --non-interactive --sync-username), $mirror_config->{'user'},
    sprintf 'svn+ssh://%s@%s%s/%s',
      $mirror_config->{'user'}, $mirror_config->{'host'}, $mirror_config->{'path'},
      $config->info('repository'),
  );
}
# `/usr/bin/svnsync synchronize --username js5 svn+ssh://js5\@web-wwwsand01.internal.sanger.ac.uk/repos/svn/pagesmith-mirror`;
exit 0;
