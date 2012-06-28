
package SangerPaths;

use strict;
use warnings;

use Otter::PerlVersion;
use Otter::EnvFix;


my $ensembl_root =
    "/nfs/WWWdev/SHARED_docs/lib/ensembl-branch-";

my $otter_root =
    "${otterlace_server_root}/lib/otter";

sub import {
    my ( $package, @tags ) = @_;

    # extract the version numbers from the import tags

    my ( $ensembl_version, $otter_version, $humpub );

    foreach my $tag (@tags ) {
        my $version;
        ($version) = $tag =~ /^ensembl(.*)$/;
        $ensembl_version = $version if defined $version;
        ($version) = $tag =~ /^otter(.*)$/;
        $otter_version   = $version if defined $version;
        ($humpub) = $tag =~ /^humpub$/;
    }

    die "the ensembl version is not defined"
        unless defined $ensembl_version;
    die "the otter version is not defined"
        unless defined $otter_version;

    # set up the include path
    unshift @INC,
    ( sprintf '%s/%s', $otter_root, $otter_version ),
    ( map {
        sprintf '%s%s/%s', $ensembl_root, $ensembl_version, $_;
      } qw(
      modules
      ensembl/modules
      ensembl-variation/modules
      ), ),
    ;

#    unshift @INC, sprintf('%s/lib/humpub', $otterlace_server_root)
    die "humpub no longer provided" if $humpub;

    return;
}

1;
