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

    # Feed some bogus-but-safe authentication info to SangerWeb
    # (provided in sibling file) and Bio::Otter::Server::Support::Web
    #
    # webvm-cgi-run can pre-load the username on command line.
    # Otherwise, it is safer to avoid names that give uncontrolled
    # write access (e.g. plain username = member of staff = write
    # anywhere)
    $ENV{BOGUS_AUTH_USERNAME} ||= (getpwuid($<))[0].'@fake.sangerweb';
    $ENV{HTTP_CLIENTREALM} = 'sanger,bogus'; # emulate a local user
    warn "This is DEVEL mode - bogus authentication ($ENV{BOGUS_AUTH_USERNAME}) in use";

    # Error-wrapping is for running on command line (cgi_wrap)
    $Bio::Otter::Server::Support::Web::ERROR_WRAPPING_ENABLED =
      $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED} ? 1 : 0
        if defined $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED};

    # disable compression
    $Bio::Otter::Server::Support::Web::COMPRESSION_ENABLED = 0;

    return ();
}


1;
