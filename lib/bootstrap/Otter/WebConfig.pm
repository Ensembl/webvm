package Otter::WebConfig;
use strict;
use warnings;

use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR);
use YAML::Loader;

use base 'Exporter';
our @EXPORT_OK = qw( get_configuration config_extract host_svndir );


my ($ROOT_PATH, $service_key);

sub __init {
    $ROOT_PATH = '/www/utilities'; # will only work on webteam VMs
    $service_key = 'otter';
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
    my ($cfg) = @_;
    $cfg = get_configuration() if !defined $cfg;

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
            +{ type => $k, hostname => $_,
               write => $rw{write}, read => $rw{read} }
        } @servers;
    }

    return \@out;
}


__init();

1;
