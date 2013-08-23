package Otter::Paths;

use strict;
use warnings;

require lib;


=head1 NAME

Otter::Paths - add elements to @INC by tag name

=head1 DESCRIPTION

This has evolved during the separation from L<SangerPaths>, which is
based on L<Module::PortablePath>.

It is small, stand-alone and intended to be installed as part of the
webserver configuration.

=head1 AUTHOR

mca@sanger.ac.uk

=cut


sub import {
    my ( $package, @tags ) = @_;

    my @lib;
    foreach my $tag (@tags) {
        if (my ($what, $vsn) = $tag =~ m{^(bioperl|core|ensembl|humpub|intweb|otter)(\d+|)$}) {
            push @lib, $package->$what($vsn);
        } else {
            die "Failed to supply '$tag'";
        }
    }

    # append to @INC ('use lib' prepends), maintaining order
    # but leaving system libs at the end
    my @old_INC = grep { not m{^/usr/} } @INC;
    lib->import(@lib);
    lib->import(@old_INC);
    # This perverse arrangement gives the benefits of 'use lib' but
    # allows to append, which we must do to keep OTTER_PERL_INC at top
    # priority.

# Note that we do not want to pick up the wrong version of
# Bio::Perl from /usr/share/perl5/Bio/SeqIO.pm

    return;
}


# Derive the WEBDIR, i.e. the root of webvm.git
#
# Get it from our location, since we are part of that.
# We could instead take a PassEnv from Apache.
sub webdir {
    if (__FILE__ =~ m{^(.*)/lib/bootstrap/Otter/Paths\.pm$}) {
        return $1;
    } else {
        die 'Cannot derive $WEBDIR from '.__FILE__;
    }
}

sub localdeps {
    return webdir().'/apps/webvm-deps';
}


sub _wantdir {
    my ($what, $available, @dirs) = @_;
    foreach my $dir (@dirs) {
        return $dir if -d $dir;
    }

    my @available; # to tell what there IS

    # aliases
    while (@$available && !ref($available->[0])) {
        push @available, shift @$available;
    }

    # findable directories
    my ($regex, @dir) = @$available;
    foreach my $dir (@dir) {
        next unless -d $dir;
        opendir my $dh, $dir or die "opendir($dir) failed: $!";
        my @leaf = grep { not m{^\.\.?$} } readdir $dh;
        foreach my $leaf (@leaf) {
            my @part = "$dir/$leaf" =~ $regex;
            next unless @part;
            push @available, join '', @part;
        }
    }
    my %uq;
    @uq{@available} = ();
    @available = sort keys %uq;

    $available = (@dir && $regex) ? "  Found none in (@dir) =~ $regex\n" : '';
    $available = "  Available are (@available)\n" if @available;
    die "Cannot find $what.\n  Looked for @dirs\n$available";
}


sub intweb {
    # no-op: intweb is a subset of core which we don't provide
    # Catching this allows other tags to be fatal
    return ();
}

sub core {
    my ($pkg, undef) = @_; # takes no version

    my $SHARED_core = _wantdir
      ('.../SHARED_docs/lib/core',
       [],
       localdeps().'/SHARED.core',
       '/nfs/WWWdev/SHARED_docs/lib/core',
       '/nfs/WWW/SHARED_docs/lib/core');

# real SangerPaths qw(core) provides all of
#    a) /WWW/SHARED_docs/lib/core
#    b) /WWW/SANGER_docs/perl
#    c) /WWW/SANGER_docs/bin-offline
#    d) /usr/local/oracle/lib onto LD_LIBRARY_PATH
#
# this code provides
#    a) copy of
#
# and ignores
#    b) contains modules we are not interested in (Pfetch.pm)
#       or actively do not want (SangerPaths.pm)
#    c) not relevant to Otter Server
#    d) not required

    die "SHARED.core is incomplete" unless -d "$SHARED_core/Website/SSO";


    # These modules won't load unless we provide some larger
    # dependencies.  We don't need them, just authentication...  but
    # these are pulled into SangerWeb.
    #
    # Nobble them here - horrible, but better than carrying a diff on
    # SiteDecor.pm (which already carries an in-copy diff to its CVS
    # repo)
    my @cant_mods = qw{
 SiteDecor/ccc.pm
 Website/portlet/getblast.pm
 Website/portlet/news.pm
 Website/portlet/calendar.pm
 Website/portlet/special.pm
       };
    @INC{@cant_mods} = ("(prevented by $pkg)") x @cant_mods;


    return $SHARED_core;
}


sub bioperl {
    my ($pkg, $vsn_short) = @_;

    my %known_vsn =
      (123 => '1.2.3',
       '' => '1.5.2_100', # 2006 vintage aka. "bioperl-live"
      );

    my $version = $known_vsn{$vsn_short} || $vsn_short;
    my @deps =
      (localdeps(),
       '/nfs/WWWdev/SHARED_docs/lib',
       '/nfs/WWW/SHARED_docs/lib');

    my $bioperl = _wantdir
      ("Bioperl $vsn_short ($version)",
       [ (map {"bioperl$_"} keys %known_vsn),
         qr{/(bioperl)-([^/]*)$}, @deps ],
       map { "$_/bioperl-$version" } @deps);

    die "bioperl$vsn_short is incomplete" unless -d "$bioperl/Bio";
    return $bioperl;
}


sub otter {
    my ($pkg, $otter_version) = @_;
    my $otterlace_server_root = $pkg->code_root;
    my $libs = "$otterlace_server_root/lib/otter";
    return _wantdir("Otter Server v$otter_version",
                    [ qr{(otter)/(\d+)}, $libs ],
                    "$libs/$otter_version");
}

sub code_root { # XXX:DUP Bio::Otter::Server::Config->data_dir
    my ($pkg) = @_;

    # The usual way to find code
    my $DR  = ($ENV{DOCUMENT_ROOT}        ||'');

    # Accepted to follow cgi_wrap convention, but not used?
    # Bio::Otter::Server::Config doesn't use it
    my $OSR = ($ENV{OTTERLACE_SERVER_ROOT}||'');

    my $out; # NB: untainted by pattern match
    $out   = $1 if $OSR =~ m(\A(.+?)/?$);
    $out ||= $1 if $DR  =~ m(\A(.+)/htdocs/?$);

    die "Need OTTERLACE_SERVER_ROOT or DOCUMENT_ROOT to find Otter Server files"
      unless defined $out;
    die "OTTERLACE_SERVER_ROOT=$OSR,DOCUMENT_ROOT=$DR => directory $out (absent)"
      unless -d $out;

    return $out;
}


sub ensembl {
    my ($pkg, $ensembl_version) = @_;

    my @deps =
      (localdeps(), # our local copy
       '/nfs/WWWdev/SHARED_docs/lib', # webteam central, seen from deskpro
       '/nfs/WWW/SHARED_docs/lib'); # webteam central, seen from old webserver

    my $ensembl_root = _wantdir
      ("Ensembl v$ensembl_version",
       [ qr{/(ensembl)-branch-([^/]*)$}, @deps ],
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

    die "Ensembl v$ensembl_version is missing components (@lib)"
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
       [],
       localdeps().'/humpub', # our local copy
       '/nfs/WWWdev/SANGER_docs/lib/humpub',
       '/nfs/WWW/SANGER_docs/lib/humpub');

    die "humpub at $humpub is incomplete" unless -d "$humpub/Hum";

    return $humpub;
}

1;
