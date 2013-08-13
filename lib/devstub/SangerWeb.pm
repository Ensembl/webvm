
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
