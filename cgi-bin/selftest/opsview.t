#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More;

use Sys::Hostname 'hostname';
use Try::Tiny;
use YAML 'Dump';
use LWP::UserAgent;
use JSON 'decode_json';
use List::Util 'sum';

use Otter::WebNodes;

=head1 DESCRIPTION

Ask the local Opsview about this webserver, using the REST API.

http://docs.opsview.com/doku.php?id=opsview-core:restapi

=cut


my $BASE = 'https://opsview.internal.sanger.ac.uk';
sub main {
    plan skip_all => 'Only runs on a back-end context'
      if Otter::WebNodes->new_cgi->is_frontend;

    plan tests => 3;

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $prog = $ENV{SCRIPT_URI} || $0;
    $ua->agent("$prog ");
    $ua->timeout(10);
    # We will visit other webservers, not ourself

    my @auth_hdrs = try {
        # see RT#362580
        auth_hdrs(mca => 'fc48f042c9231ce5bab8e992cf8b14a6306f2c72');
#        do_login($ua, 'readonly', 'we_dont_have_one');
    } catch {
        diag "Authentication problem: $_";
    };
    is(scalar @auth_hdrs, 4, "Got some kind of authentication headers");

    # http://docs.opsview.com/doku.php?id=opsview-core:restapi:status
    my $host = hostname();
#$host = 'does-not-cromulate';
    my $data = do_rest($ua, get => 'status/host', \@auth_hdrs,
                       host => $host,
                      );

    my $host_data;
    is((try { scalar(($host_data) = @{ $data->{list} }) }
        catch {"ERR:$_"}),
       1, "Got one host from status/host");
    diag "See $BASE/status/service?host=$host";

    {
        local $TODO = opsview_unhandled($host_data);
        subtest Status => sub { diagnose($host, $host_data) };
    }

    diag Dump($data);

    return 0;
}


sub diagnose {
    my ($host, $host_data) = @_;
    my $S = $host_data->{summary};

    is($host_data->{name}, $host, "Expected hostname");

    my $ok = h_count($S->{ok});
    cmp_ok($ok, '>', 0, 'Some OK services');
    is($ok, h_count($S->{total}), 'Host+services all OK');

    my %prob;
    while (my ($k, $v) = each %$S) {
        next if grep { $k eq $_ } qw{ handled ok total unhandled };
        my $n = h_count($v);
        is($n, 0, "'$k' items");
    }

    return;
}

sub opsview_unhandled {
    my ($host_data) = @_;

    return try {
        my $S = $host_data->{summary};
        if ($S->{unhandled} eq '0' && h_count($S->{ok}) < $S->{total}) {
            # an excuse for what follows..
            return 'Marked as "handled" in Opsview';
        } else {
            return (); # no excuses
        }
    } catch {
        diag "Could not extract summary for deciding TODO: $_";
        return (); # no excuses
    };
}

sub h_count {
    my ($hash_ref) = @_;
    return $hash_ref if defined $hash_ref && !ref($hash_ref);
    return sum(0, values %{ $hash_ref || {} });
}

sub do_login {
    my ($ua, $u, $p) = @_;

    my $data = do_rest
      ($ua, post => 'login', [], username => $u, password => $p);

    my @out;
    try {
        my $token = $data->{token} or die "found no token";
        @out = auth_hdrs($u, $token);
    } catch {
        die "Opsview login gave $_";
    };

    return @out;
}

sub do_rest {
    my ($ua, $method, $loc, $hdrs, @kvp) = @_;

    my $uri = URI->new("$BASE/rest/$loc");
    if ($method eq 'get') {
        $uri->query_form(\@kvp, ';');
        @kvp = ();
    }

    my $resp = $ua->$method($uri, Accept => 'application/json', @$hdrs);

    die "Opsview request to $loc failed: ".$resp->status_line
      unless $resp->is_success;

    my $t = $resp->content_type;
    die "Opsview request to $loc returned content-type $t"
      unless $t eq 'application/json';

    return decode_json $resp->decoded_content;
}

sub auth_hdrs {
    my ($u, $t) = @_;
    ### http://docs.opsview.com/doku.php?id=opsview-core:restapi#logging_in_to_the_api_via_authtkt
    #
    # <form action="https://opsview.internal.sanger.ac.uk/rest/login_tkt" method="POST">
    #  <input type="text" name="username" value="mca">
    #  <input type="submit" value="Go">
    # </form>
    #
    # So we ride the cookie existing in the browser
    return ('X-Opsview-Username' => $u, 'X-Opsview-Token' => $t)
}

main();
