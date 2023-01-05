=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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


package SangerWeb;

use strict;
use warnings;

use Otter::EnvFix;
use Carp;

sub new {
    my ($pkg) = @_;
    my $self = {};
    bless $self, $pkg;
    return $self;
}

sub username {
    my $username = $ENV{BOGUS_AUTH_USERNAME};
    confess "No development-mode username was given" unless defined $username;
    return $username;
}

my $cgi;
sub cgi {
    require CGI;
    return $cgi ||= CGI->new;
}

1;
