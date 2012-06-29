package Otter::Paths;

use strict;
use warnings;

require lib;


sub import {
    my ( $package, @tags ) = @_;

    my @lib;
    foreach my $tag (@tags) {
        if (my ($what, $vsn) = $tag =~ m{^(bioperl|ensembl|otter|humpub)(\d+|)$}) {
            push @lib, $package->$what($vsn);
        } else {
            warn "Failed to supply '$tag'";
        }
    }

    # prepend to @INC, maintaining order
    lib->import(@lib);

    return;
}


# Derive the WEBDIR, i.e. the root of webvm.git
#
# Get it from our location, since we are part of that.
# We could instead take a PassEnv from Apache.
sub webdir {
    return $1 if __FILE__ =~ m{^(.*)/lib/bootstrap/Otter/Paths\.pm$};
    die 'Cannot derive $WEBDIR from '.__FILE__;
}

sub localdeps {
    return webdir().'/apps/webvm-deps';
}


sub _wantdir {
    my ($what, @dirs) = @_;
    foreach my $dir (@dirs) {
        return $dir if -d $dir;
    }
    die "Cannot find $what.  Looked for @dirs";
}


sub bioperl {
    my ($pkg, $vsn_short) = @_;

    my %known_vsn =
      (123 => '1.2.3',
      );

    my $version = $known_vsn{$vsn_short} || $vsn_short;
    my @deps =
      (localdeps(),
       '/nfs/WWWdev/SHARED_docs/lib',
       '/nfs/WWW/SHARED_docs/lib');

    my $bioperl = _wantdir
      ("Bioperl $vsn_short ($version)",
       map { "$_/bioperl-$version" } @deps);

    die "bioperl$vsn_short is incomplete" unless -d "$bioperl/Bio";
    return $bioperl;
}


sub otter {
    my ($pkg, $otter_version) = @_;

    # XXX:DUP Otter::EnvFix
    my ($otterlace_server_root) = # NB: untainted by pattern match
      ($ENV{OTTERLACE_SERVER_ROOT}||'') =~ m(\A(.*?)/?$)
        or die "Need OTTERLACE_SERVER_ROOT to find Otter v$otter_version";

    return sprintf '%s/lib/otter/%s', $otterlace_server_root, $otter_version;
}


sub ensembl {
    my ($pkg, $ensembl_version) = @_;

    my @deps =
      (localdeps(), # our local copy
       '/nfs/WWWdev/SHARED_docs/lib', # webteam central, seen from deskpro
       '/nfs/WWW/SHARED_docs/lib'); # webteam central, seen from old webserver

    my $ensembl_root = _wantdir
      ("Ensembl v$ensembl_version",
       map { "$_/ensembl-branch-$ensembl_version" } @deps);

    my @lib = map { "$ensembl_root/$_" }
# team_tools cgi_wrap (local Apache wrapper) did this
#      qw{
#  modules
#  ensembl/modules
#  ensembl-variation/modules
#    };
#
# Webteam SangerPaths (old webservers) supplied these,
# If we cut some out, we might also drop them from webvm-deps.git
      qw{
  ensembl-draw/modules
  ensembl-variation/modules
  ensembl-compara/modules
  modules
  ensembl-external/modules
  ensembl/modules
  ensembl-functgenomics/modules
    };

    die "Ensembl v$ensembl_version is incomplete (@lib)"
      if grep { ! -d $_ } @lib;

    return @lib;
}


# humpub is only used by the Otter Server during scripts/apache/test
# when we try to load everything (including client libraries)
sub humpub {
    my ($pkg, $humpub_version) = @_;
    die "humpub not yet versioned" if $humpub_version ne '';

    my $humpub = _wantdir
      ("humpub modules",
       localdeps().'/humpub', # our local copy
       '/nfs/WWWdev/SANGER_docs/lib/humpub',
       '/nfs/WWW/SANGER_docs/lib/humpub');

    die "humpub is incomplete" unless -d "$humpub/Hum";

    return $humpub;
}

1;
