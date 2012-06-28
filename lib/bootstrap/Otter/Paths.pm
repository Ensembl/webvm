package Otter::Paths;

use strict;
use warnings;

require lib;


sub import {
    my ( $package, @tags ) = @_;

    my @lib;
    foreach my $tag (@tags) {
        if (my ($what, $vsn) = $tag =~ m{^(ensembl|otter)(\d+)$}) {
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
      (webdir().'/apps/webvm-deps', # our local copy
       '/nfs/WWWdev/SHARED_docs/lib', # webteam central, seen from deskpro
       '/nfs/WWW/SHARED_docs/lib'); # webteam central, seen from old webserver

    my $ensembl_root;
    foreach my $dir (@deps) {
        $ensembl_root = "$dir/ensembl-branch-$ensembl_version";
        last if -d $ensembl_root;
    }
    die "Cannot find Ensembl v$ensembl_version.  Looked in @deps"
      unless $ensembl_root;

    my @lib = map { "$ensembl_root/$_" }
# team_tools cgi_wrap (local Apache wrapper) did this
#      qw{
#  modules
#  ensembl/modules
#  ensembl-variation/modules
#    };
#
# Webteam SangerPaths (old webservers) did this.
# If we cut some out, we might also drop them from webvm-deps.git
      qw{
  ensembl-draw/modules
  ensembl-variation/modules
  ensembl-compara/modules
  modules
  ensembl-external/modules
  ensembl/modules
  ensembl-pipeline/modules
  ensembl-webcode/modules
  ensembl-functgenomics/modules
    };

    die "Ensembl v$ensembl_version is incomplete (@lib)"
      if grep { ! -d $_ } @lib;

    return @lib;
}


1;
