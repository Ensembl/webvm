
package SangerWeb;

use strict;
use warnings;

use Otter::EnvFix;

my $username = (getpwuid($<))[0];

sub new {
    my ($pkg) = @_;
    my $self = {};
    bless $self, $pkg;
    return $self;
}

sub username {
    return $username;
}

my $cgi;
sub cgi {
    require CGI;
    return $cgi ||= CGI->new;
}

1;
