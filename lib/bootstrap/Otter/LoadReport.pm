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

BEGIN { show('BEGIN') }
END   { show('END')   }

1;
