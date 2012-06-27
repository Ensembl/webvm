package Otter::EnvFix;

use strict;
use warnings;


=head1 NAME

Otter::EnvFix - Otter Server environment fixes, from Bash or CGI


=head1 DESCRIPTION

Miscellaneous patches to the environment.

Some of these interfere with authentication and are only suitable for
development mode.  Warning is given, they will need weeding out later.


=head1 AUTHOR

mca@sanger.ac.uk
jh13@sanger.ac.uk

=cut


sub import {
    my ($otterlace_server_root) = # NB: untainted by pattern match
      ($ENV{OTTERLACE_SERVER_ROOT}||'') =~ m(\A(.*?)/?$);

    die sprintf "cannot guess OTTERLACE_SERVER_ROOT from script path '%s'", $0
      unless defined $otterlace_server_root;

    ## no critic (Variables::RequireLocalizedPunctuationVars)

    # patch the environment to prevent ServerScriptSupport.pm throwing
    # an error when running from the command line
    $ENV{DOCUMENT_ROOT} = "${otterlace_server_root}/htdocs";
    $ENV{HTTP_CLIENTREALM} = 'sanger'; # emulate a local user

    # set error-wrapping
    $Bio::Otter::ServerScriptSupport::ERROR_WRAPPING_ENABLED =
      $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED} ? 1 : 0;

    # disable compression
    $Bio::Otter::ServerScriptSupport::COMPRESSION_ENABLED = 0;

    warn "Should be in DEVEL mode";

    return ();
}


1;
