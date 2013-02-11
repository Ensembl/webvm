package Otter::EnvFix;

use strict;
use warnings;
require Otter::Paths;


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
    my $otterlace_server_root = Otter::Paths->code_root;

    ## no critic (Variables::RequireLocalizedPunctuationVars)

    # patch the environment to prevent ServerScriptSupport.pm throwing
    # an error when running from the command line
    $ENV{DOCUMENT_ROOT} = "${otterlace_server_root}/htdocs";
    $ENV{HTTP_CLIENTREALM} = 'sanger'; # emulate a local user

    # Error-wrapping is for running on command line (cgi_wrap)
    $Bio::Otter::ServerScriptSupport::ERROR_WRAPPING_ENABLED =
      $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED} ? 1 : 0
        if defined $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED};

    # disable compression
    $Bio::Otter::ServerScriptSupport::COMPRESSION_ENABLED = 0;

    warn "Should be in DEVEL mode";

    return ();
}


1;
