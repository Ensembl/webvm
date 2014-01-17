#! /usr/bin/perl -T

use strict;
use warnings;

BEGIN { use lib ($ENV{OTTER_PERL_INC} || q{}) =~ m{([^:]+)}g }
use Otter::PerlVersion;
use Otter::Paths qw( HTtapTP-0.04 );
use Test::HTtapTP ':cors_ok';
use Test::More tests => 6;
use Otter::WebNodes;
use Try::Tiny;
use File::Temp;

my $me = Otter::WebNodes->new_cgi;
foreach my $tst ([ "/tmp" => "/tmp" ],
                 [ "Apache tmp" => $me->webtmpdir ]) {
    my ($name, $dir) = @$tst;

  SKIP: {
        ok($dir && -d $dir, "$name directory exists: ".($dir || '[undef]'))
          or skip "Don't know what to test", 2;

        my $fh = try {
            File::Temp->new(TEMPLATE => '04write-tmp.t.XXXXXX', DIR => $dir);
        } catch { "ERR:$_" };

        ok(ref($fh), "Made tmp in $dir") or
          skip "tmpfile in $dir failed $fh", 1;

        my $fn = $fh->filename;
        diag $fn;
        print {$fh} "text\n";
        close $fh;

        is(5, (-s $fh->filename), "length of file $fn");
    }
}
