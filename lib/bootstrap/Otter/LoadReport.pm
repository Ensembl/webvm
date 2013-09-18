package Otter::LoadReport;
use strict;
use warnings;

=head1 NAME

Otter::LoadReport - write load average to error_log

=head1 DESCRIPTION

Record system load and script runtime in the Apache error_log.

=head2 Caveat

For fast scripts, the load may not update until some time after the
script finishes.  Subsequent script BEGIN or END will fill in the data
when load is heavy.

=cut


use File::Slurp qw( slurp );
use Time::HiRes qw( tv_interval gettimeofday );

sub loadavg {
    # Linux only
    my @load = (split /\s+/, slurp('/proc/loadavg'))[0,1,2]; # 1min, 5min, 15min
    return @load;
}

my $t;
sub show {
    my ($when) = @_;

    my @load = loadavg();
    my @out = ("loadavg (@load)");

    if ($t) {
        my @cpu = times();
        push @out, (wallclock => tv_interval($t), "cpu (@cpu)");
    }
    $t ||= [ gettimeofday() ];

    print STDERR "$ENV{SCRIPT_NAME} pid=$$ $when: @out\n";

    return;
}

BEGIN { show('BEGIN') }
END   { show('END')   }

1;
