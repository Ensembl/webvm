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

package Otter::LoadReport;
use strict;
use warnings;

=head1 NAME

Otter::LoadReport - write load average to error_log

=head1 DESCRIPTION

Record system load, memory info and script runtime in the Apache
error_log.

=head2 Caveat

For fast scripts, the load may not update until some time after the
script finishes.  Subsequent script BEGIN or END will fill in the data
when load is heavy.

=cut

use Time::HiRes qw( tv_interval gettimeofday );
use Try::Tiny;


sub loadavg {
    my @load;
    my $linux_fn = '/proc/loadavg';
    if ( try { require Sys::LoadAvg; } ) {
        @load = Sys::LoadAvg::loadavg();
    } elsif ( -r $linux_fn ) {
        if (open my $fh, '<', $linux_fn) {
            @load = (split /\s+/, scalar <$fh>)[0,1,2]; # 1min, 5min, 15min
        } else {
            @load = ("read $linux_fn: $!");
        }
    } else {
        @load = ( 'load unavailable' );
    }
    return @load;
}

sub run_ps {
    return try {
        local $ENV{PATH} = '/bin:/usr/bin';
        my ($r, $v) =
          map { int($_ / 1024 + 0.5) }
            qx{ ps -o rss= -o vsz= $$ } =~ m{(\d+)}g;
        return "(rss:${r} vsz:${v})MiB";
    } catch {
        return "fail:$_";
    };
}

my $t;
sub show {
    my ($when) = @_;

    my @load = loadavg();
    my @out = (at => $when, loadavg => "(@load)");

    if ($t) {
        my @cpu = times();
        push @out,
          (wallclock => sprintf("%.2fs", tv_interval($t)),
           "cpu (@cpu)s",
           exit => $?,
           ps => run_ps());
    } else {
        my $x_fwd = $ENV{HTTP_X_FORWARDED_FOR};
        $x_fwd = '-' unless defined $x_fwd && $x_fwd ne '';
        $x_fwd =~ s{([^-_A-Za-z0-9.:,])}{sprintf("%%%02x", ord($1))}eg;
        push @out,
          (script => $ENV{SCRIPT_NAME},
           fwd => $x_fwd);
    }
    $t ||= [ gettimeofday() ];

    print STDERR "pid $$: @out\n";

    return;
}

# Log request like the access_log, so we can link them
sub accesslog {
    return unless defined $ENV{REQUEST_METHOD};
    my $req = join '', $ENV{REQUEST_METHOD}, ' ', $ENV{REQUEST_URI}, ' ', $ENV{SERVER_PROTOCOL};
    $req =~ s{([^ -\x7F])}{sprintf("\\x%02x", ord($1))}eg;
    print STDERR "pid $$: $req\n";
    return;
}


BEGIN { show('BEGIN'); accesslog(); }
END   { show('END')   }

1;
