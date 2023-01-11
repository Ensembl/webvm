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

package Otter::WebConfig;
use strict;
use warnings;

use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR);
use YAML::Loader;

use Sys::Hostname 'hostname';
use Otter::Paths;

use base 'Exporter';
our @EXPORT_OK = qw( config_extract host_svndir );


=head1 NAME

Otter::WebConfig - handle configuration relating to webteam servers

=head1 DESCRIPTION

This module encapsulates parts of the webteam standard layout, from
the point of view of webvm.git code.

This is an uncooked interface.  Try L<Otter::WebNodes> first.

=cut


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
    my ($cfg, $no_fixup) = @_;
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

    die "code removed" unless $no_fixup;

    return \@out;
}


__init();

1;
