package Otter::EnvFix;

use strict;
use warnings;


my ($otterlace_server_root) = # NB: untainted by the pattern match, first one wins
  (($ENV{OTTERLACE_SERVER_ROOT}||'') =~ m(\A(.*?)/?$),
   $0 =~ m(\A(.*)/cgi-bin/));

die sprintf "cannot guess OTTERLACE_SERVER_ROOT from script path '%s'", $0
  unless defined $otterlace_server_root;

# patch the environment to prevent ServerScriptSupport.pm throwing an
# error when running from the command line
$ENV{DOCUMENT_ROOT} = "${otterlace_server_root}/htdocs";
$ENV{HTTP_CLIENTREALM} = 'sanger'; # emulate a local user

# set error-wrapping
$Bio::Otter::ServerScriptSupport::ERROR_WRAPPING_ENABLED =
    $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED} ? 1 : 0;

# disable compression
$Bio::Otter::ServerScriptSupport::COMPRESSION_ENABLED = 0;


1;
