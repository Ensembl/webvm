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


use File::Slurp qw( slurp );
use Time::HiRes qw( tv_interval gettimeofday );
use Try::Tiny;


sub loadavg {
    my @load;
    if ( -r '/proc/loadavg' ) {
        @load = (split /\s+/, slurp('/proc/loadavg'))[0,1,2]; # 1min, 5min, 15min
    } elsif ( try { require Sys::LoadAvg; } ) {
        @load = Sys::LoadAvg::loadavg();
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
    my @out = (pid => $$, "loadavg (@load)");

    if ($t) {
        my @cpu = times();
        push @out,
          (wallclock => sprintf("%.2fs", tv_interval($t)),
           "cpu (@cpu)s",
           ps => run_ps());
    }
    $t ||= [ gettimeofday() ];

    print STDERR "$ENV{SCRIPT_NAME} $when: @out\n";

    return;
}

BEGIN { show('BEGIN') }
END   { show('END')   }

1;
