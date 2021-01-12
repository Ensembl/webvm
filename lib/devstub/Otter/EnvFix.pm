=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

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
