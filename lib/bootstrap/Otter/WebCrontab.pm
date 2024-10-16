=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Otter::WebCrontab;

use strict;
use warnings;

use Sys::Hostname 'hostname';
use Digest::SHA 'sha1';

use base 'Exporter';
our @EXPORT_OK = qw( invent_crontab );

=head1 NAME

Otter::WebCrontab - decide what "crontab -l" should contain

=head1 DESCRIPTION

Factored out of F<cgi-bin/crontab> for F<cgi-bin/selftest/crontab>

=head1 AUTHOR

mca@sanger.ac.uk

=cut


sub invent_crontab {
    my $hostname = hostname();

    # What am I?
    my $user = getpwuid($<);
    my $live = $hostname =~ m{^web-\w+(staging|live)-?\d+($|\.)};
    my $dlu;
    if ($user eq 'www-core') {
        $dlu = $live ? 'www-live' : 'www-dev';
    } else {
        # sandbox
        $dlu = '$LOGNAME/www-dev'; # literal variable name
    }

    # Phase the crontab across hosts
    my ($shhost) = $hostname =~ m{^([^.]+)}
      or die "Can't get short hostname from $hostname";
    my $hostnum = unpack('N', sha1($shhost));

    my $perfive = join ',', map { $_ * 5 + ($hostnum % 5) } (0..11);
    my $hrly_min = $hostnum % 60;

    return <<"TXT";
# m h  dom mon dow   command

\@reboot        /www/$dlu/utilities/start
# DNW due to LDAP not coming up before crond

$perfive *   * * *   /www/$dlu/tools/ensure-fast /www/tmp/$dlu

$hrly_min 21   * * Sun /www/$dlu/utilities/rotate
TXT
}

1;
