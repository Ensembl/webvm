#! /usr/bin/perl -T

use strict;
use warnings;
use File::Slurp 'slurp';
use Sys::Hostname 'hostname';

print "Content-type: text/plain\n\n";

print hostname(), "\n\n";
print slurp('/proc/cpuinfo'), "\n\n";
print slurp('/proc/meminfo'), "\n\n";

=head1 AUTHOR

mca@sanger.ac.uk

=cut
