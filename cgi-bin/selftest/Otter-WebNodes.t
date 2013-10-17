#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );

use Test::HTtapTP ':cors_ok';
use Test::More;
use Net::Domain 'hostfqdn';
use Try::Tiny;

use Otter::WebNodes;


my ($hostname, $me);
sub main {
    plan tests => 3;

    $hostname = ($ENV{GATEWAY_INTERFACE}
                 ? CGI->new->virtual_host
                 : hostfqdn());

    $me = Otter::WebNodes->new_cgi;

    subtest in_config => \&in_config_tt;
    subtest in_fixup =>  \&in_fixup_tt;
    subtest back2front => \&back2front_tt;

    return 0;
}

sub in_config_tt {
    diag <<WHY;
Ensuring the backends are listed in the webteam svn configuration on
each host should mean that we have access via smithssh(1)
WHY
    if ($me->type eq 'sandbox') {
        # Message-ID: <20131015125252.GM5561@sanger.ac.uk>
        plan skip_all => 'sandboxes are not expected in the config (files are not written there by www-core)';
    }

    return in_list('listnew_config');
}

sub in_fixup_tt {
    diag <<WHY;
Ensuring every frontend & backend is somehow discovered by
listnew_fixed should mean that tests can reason about all servers.
This is a bit recursive but it's worth a try.
WHY
    return in_list('listnew_fixed');
}

sub back2front_tt {
    diag <<WHY;
Ensuring the backends are all expected to be included in a frontend
(reverse proxy) allows the list to be used to check for other
problems.
WHY

    plan skip_all => 'this is not a backend' if $me->is_frontend;

    my @front = grep { $_->frontend_contains($me) }
      Otter::WebNodes->listnew_fixed;

    my $me_base = $me->base_uri;
    my @front_base = map { $_->base_uri } @front;
    is(scalar @front, 1,
       "this backend ($me_base) is expected in one frontend (@front_base)")
      or diag explain { front => \@front };

    return 0;
}


sub in_list {
    my ($method) = @_;

    my @srv = Otter::WebNodes->$method;

    my $ok = 1;

    my @here = grep { $hostname eq $_->vhost } @srv;
    my @here_me;

    $ok &= cmp_ok(scalar @here, '>', 0,
                  "$method list includes this machine ($hostname)");

    if (1 == @here && $here[0]->is_frontend) {
      SKIP: {
            skip "cannot check webdir on frontend", 1;
        }
        @here_me = @here;

    } elsif (!grep { $_->is_frontend } @here) {
        # backends only - they should have a webdir
        my $WEBDIR = $me->webdir;
        @here_me = grep { $WEBDIR eq $_->webdir } @here;
        $ok &= cmp_ok(scalar @here_me, '==', 1,
                      "list includes this WEBDIR ($WEBDIR) once");

    } else {
        fail("weird?");
        $ok = 0;
    }

  SKIP: {
        my $n = @here_me;
        skip "cannot test base_uri on n=$n", 1 unless 1 == $n;
        $ok &= is($here_me[0]->base_uri, $me->base_uri, "base_uri match");
    }

    diag explain { srv => \@srv, here => \@here } unless $ok;

    return 0;
}


main();
