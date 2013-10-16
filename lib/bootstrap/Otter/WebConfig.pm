package Otter::WebConfig;
use strict;
use warnings;

use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR);
use YAML::Loader;

use Sys::Hostname 'hostname';
use Otter::Paths;

use base 'Exporter';
our @EXPORT_OK = qw( get_configuration config_extract host_svndir server_base_url );


=head1 NAME

Otter::WebConfig - handle configuration relating to webteam servers

=head1 DESCRIPTION

This module encapsulates parts of the webteam standard layout, from
the point of view of webvm.git code.

(It probably needs to grow into a class by now.)

=cut


my ($ROOT_PATH, $service_key);
our ($DOMAIN, %PORT); ##used

sub __init {
    $ROOT_PATH = '/www/utilities'; # will only work on webteam VMs
    $service_key = 'otter';
    $DOMAIN = '.internal.sanger.ac.uk';

    # XXX: Could look up port numbers in ServerRoot/conf/user/*.conf
    # "Listen" lines but they are fairly static.
    %PORT = qw( www-core 8000 jgrg 8001 jh13 8002 mca 8003 mg13 8004 );

    return;
}


sub host_svndir {
    return $ROOT_PATH;
}


sub get_configuration { # based on /www/utilities/restricted-scp v196
  my $contents;
  if( open my $fh, q(<), "$ROOT_PATH/config/scp.yaml" ) {
    local $INPUT_RECORD_SEPARATOR = undef;
    $contents = <$fh>;
    close $fh; ## no critic (RequireChecked)
  } else {
    die "Unable to read YAML file\n";
  }
  my $yl   = YAML::Loader->new;
  my $raw_config = $yl->load( $contents );
  die "Unable to parse YAML file\n" unless $raw_config;
  return $raw_config;
}


sub config_extract { # by inspection of /www/utilities/config/scp.yaml v195
    my ($cfg, $no_fixup) = @_;
    $cfg = get_configuration() if !defined $cfg;

##called
    my @out;
    die "No useful config found" unless $cfg->{$service_key}{live};
    while (my ($k, $v) = each %{ $cfg->{$service_key} }) {
        my @servers = @{ $v->{servers} }
          or die "No servers in '$k'";
        my %paths = %{ $v->{paths} }
          or die "No paths in '$k'";
        my %rw = reverse %paths;
        die "Confused by paths - need (read, write)"
          unless 2 == keys %paths && 2 == keys %rw;

        push @out, map {
            my $fqdn = $_.$DOMAIN;
            +{ type => $k, hostname => $fqdn,
               write => $rw{write}, read => $rw{read} }
        } @servers;
    }

    unless ($no_fixup) {
        # Fake up an entry for the sandbox.
        #
        # It's not going to be listed in config/scp.yaml because
        # www-core does not write there.
##replaced
        push @out, { hostname => 'web-ottersand-01'.$DOMAIN,
                     type => 'sandbox',
                     write => '/www/FOO/www-dev', # bogus - what did you want?
                     read => '/www/tmp/FOO/www-dev' };

### Deprecated - listnew_fixed when it's done
##copied+fixed
        # Discover others following the pattern
        my %type; # key = base, value = [ num, srv ]
        foreach my $srv (@out) {
            my ($base, $num) = $srv->{hostname} =~ m{^([^.]+?)(\d+)(?:\.|$)};
            next unless defined $base;
            next if defined $type{$base}[0] &&
              $num lt $type{$base}[0]; # avoid downgrading to numbers
            $type{$base} = [ $num, $srv ];
        }
        while (my ($base, $v) = each %type) {
            my ($num, $srv) = @$v;
            my @more_host = grep { $_ ne "$base$num" } _dns_enumerate($base, $num);
            push @out, map {
                my %h = %$srv;
                $h{hostname} = $_.$DOMAIN;
                \%h;
            } @more_host;
        }

        # Exclude those which are not real
        @out = grep { _valid_host($_->{hostname}) } @out;

        # Sort
        @out = sort { ($a->{hostname} cmp $b->{hostname}) ||
                        ($a->{write} cmp $b->{write}) } @out;
    }

    return \@out;
}


# Operates three ways,
#
#    a) given hash(es) from config_extract, do
#    implementation-dependent lookup to construct the URL(s)
#
#    b) given nothing, and not running as CGI, obtain $WEBDIR and
#    hostname to cook up case a)
#
#    c) given nothing and running as CGI, use the CGI base
sub server_base_url {
    my @server = @_;
    my @out;

    if (!@server && $ENV{GATEWAY_INTERFACE}) {
        # c)
##replaced
        require CGI;
        push @out, CGI::url(-base => 1);
    } elsif (!@server) {
        # b)
        my $webdir = Otter::Paths->webdir;
        push @server, _config_like($webdir);
    }

    foreach my $srv (@server) {
        # a)
        my $host = $srv->{hostname};
        $host .= '.internal.sanger.ac.uk' unless $host =~ m{\.}; # FQDN (ugh)
        my $port = _webdir2port($srv);
        push @out, URI->new("http://$host:$port")->canonical->as_string;
    }

    die "Cannot construct server base url" unless @out;

    return $out[0] if 1 == @out && !wantarray;
    return @out;
}

sub _config_like {
    my ($dir) = @_;
    my $type = ($dir =~ m{/www/www-(dev|live)/}
                ? $1
                : 'sandbox');

    my $tmpdir = $dir;
    $tmpdir =~ s{^/www/}{/www/tmp/}
      or die "Cannot guess WEBTMPDIR from $dir";

    my %c = (hostname => hostname(),
             write => $dir,
             read => $tmpdir,
             type => $type);

    return \%c;
}

##taken
sub _webdir2port {
    my ($self) = @_;
    my $user = $self->{write} =~ m{^/www/([-a-z0-9]+)/www-dev/} ? $1
      : 'www-core';

    return $PORT{$user} or die "Cannot get port number for user $user";
}


##called
sub _dns_enumerate {
    my ($base, $sfx) = @_;

    my @out;
    while (1) { # exits with last
        my $try = "$base$sfx";
        $sfx ++;

        if (_valid_host("$try$DOMAIN")) {
            # it's valid
            push @out, $try;
        } else {
            last;
        }
    }

    return @out;
}

sub _valid_host {
    my ($name) = @_;

    my $packed_ip = gethostbyname($name);
#    print Dump({ gethostbyname => { query => $name, packed_ip => $packed_ip } }) if $opt{debug};
    return defined $packed_ip;
}



__init();

1;
