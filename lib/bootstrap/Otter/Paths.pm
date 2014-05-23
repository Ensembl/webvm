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

=head2 Import tags

All import tags will make specified libraries are available on C<@INC>

=over 4

=item intweb, core

They take no suffix.  There is only one current version.

=item bioperl

Takes an optional suffix for the version.

=item ensembl

Requires numeric suffix for the version.

=item otter

Accepts numeric suffix for the version, or C<-dev> to indicate the
largest plain (non-feature build) numeric version present.

Also may be given bare, in which case the pathname of the calling
script must make obvious the necessary version number, and feature
branch name if any.

=back


=head1 CLASS METHODS

=cut


sub import {
    my ( $package, @tags ) = @_;

    my @lib;
    foreach my $tag (@tags) {
        if (my ($what, $vsn) = $tag =~ m{^(bioperl|core|ensembl|intweb|otter)(\d+|-dev|)$}) {
            push @lib, $package->$what($vsn);
        } elsif (($what) = $tag =~ m{^(\w+-[0-9]{1,3}[.0-9]{0,10})$}) {
            my $ld = localdeps();
            my $expect = "$ld/$what.perl5lib";
            die "Expected symlink to valid dir at $expect for '$tag'" unless
              -l $expect && -d $expect && -r _;
            push @lib, $expect;
        } elsif ($tag eq 'humpub') {
            warn "Supplying nothing for obsolete tag '$tag'";
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


=head2 webdir()

Derive and return the WEBDIR, i.e. the root of webvm.git

Currently obtains it from source file location, since L<Otter::Paths>
is part of that.  This can fail if C<@INC> was "too relative", or it
may return a relative path which will break on C<chdir>.

We could instead take a C<PassEnv> from Apache.

=cut

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
        my @leaf = _readdir($dir);
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
    die "Cannot find $what\n  Looked for @dirs\n$available";
}


# don't forget to untaint!
sub _readdir {
    my ($dir) = @_;
    return () unless -d $dir;
    opendir my $dh, $dir or die "opendir($dir) failed: $!";
    return grep { not m{^\.\.?$} } readdir $dh;
}


sub intweb {
    my ($pkg, undef) = @_; # takes no version
    # no-op: intweb is a subset of core which we don't provide
    # Catching this allows other tags to be fatal
    my ($caller_pkg) = caller(2);
    unless ($caller_pkg =~ /^SiteDecor(::|$)/) {
#        require Carp; Carp::cluck
        warn
            ("$0: $pkg tag intweb is null (from $caller_pkg)");
    }
    return ();
}

sub core {
    my ($pkg, undef) = @_; # takes no version

    my $SHARED_core = _wantdir
      ('.../SHARED_docs/lib/core',
       [],
       localdeps().'/SHARED.core',
       # ...or recipe for alternative (e.g. during development) copies..?
      );

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

    # code to prevent module loading not used, since I trimmed SHARED.core/

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
       # ...or recipe for alternative (e.g. during development) copies..?
      );

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
    if ($otter_version eq '') {
        # We have to derive it.  Happens since ensembl-otter v80, and
        # supports feature branches.
        $otter_version = _otter_auto($libs);
    } elsif ($otter_version eq '-dev') {
        # some ad-hoc script, just wants the latest Otter libs
        $otter_version = _otter_dev($libs);
    } elsif ($otter_version =~ /^\d{2,4}$/) {
        # looks like a major version number (no feature)
    } else {
        die "Cannot derive major version number or lib/otter path from otter '$otter_version'";
    }

    my $put = \$Bio::Otter::Git::WANT_MAJ_FEAT; # for Bio::Otter::Git->assert_match
    die "WANT_MAJ_FEAT already set to $$put, now want $otter_version"
      if defined $$put;
    $$put = $otter_version;

    return _wantdir("Otter Server v$otter_version",
                    [ qr{(otter)/(\d+(_[^/]+)?)}, $libs ],
                    "$libs/$otter_version");
}

sub _otter_auto {
    my ($libs) = @_;
    my ($maj_feat) = $0 =~
      m{/cgi-bin/otter/(\d{2,4}(?:_[a-zA-Z][-._a-zA-Z0-9]{0,32})?)/};
    if (!defined $maj_feat) {
        die "Cannot derive major version number or lib/otter path from \$0";
    }
    return $maj_feat
}

sub _otter_dev {
    my ($libs) = @_;
    my @vsn =
      sort { $a <=> $b }
        grep { -f "$libs/$_/Bio/Otter/Version.pm" } # actually contains files
          map { /^(\d{2,4})$/ ? ($1) : () } # detaint, numerics only
            _readdir($libs);
    return $vsn[-1];
}

# Why code_root and webdir?  They're both solving the same problem,
# but different ways.  It would be nice to unify them.
#
sub code_root { # XXX:DUP:MODIFIED Bio::Otter::Server::Config->data_dir
    my ($pkg) = @_;

    # The usual way to find code
    my $DR  = ($ENV{DOCUMENT_ROOT}        ||'');

    # Accepted to follow cgi_wrap convention, but not used?
    # Bio::Otter::Server::Config doesn't use it
    my $OSR = ($ENV{OTTERLACE_SERVER_ROOT}||'');

    my $out; # NB: untainted by pattern match
    $out   = $1 if $OSR =~ m(\A(.+?)/?$);
    $out ||= $1 if $DR  =~ m(\A(.+)/htdocs/?$);

    if (!defined $out) {
        # MODIFIED: extended because we have another source of info
        $out = $pkg->webdir;
        $ENV{DOCUMENT_ROOT} = "$out/htdocs"; # for B:O:S:C
    }

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
       # ...or recipe for alternative (e.g. during development) copies..?
      );

    my $ensembl_root = _wantdir
      ("Ensembl v$ensembl_version",
       [ qr{/(ensembl)-branch-([^/]*)$}, @deps ],
       map { "$_/ensembl-branch-$ensembl_version" } @deps);

    # Exactly which parts of the ensembl-branch-* checkout are
    # available, and what parts of those we used, has changed several
    # times.
    #
    # When wondering how it used to work, git-log is your friend.
    #
    # Right now, we take whatever directories are present.
    my @part = map { m{^(ensembl[-a-z0-9_]*)$} ? "$1/modules" :
                       die "untaint failed: unexpected '$_' in $ensembl_root/" }
      grep { m{^ensembl} && -d "$ensembl_root/$_" }
        _readdir($ensembl_root);
    my @lib = map { "$ensembl_root/$_" }
      reverse       # to have ensembl before ensembl-*
        sort @part; # _readdir gives us no ordering

    my @want_part = qw( ensembl-variation/modules ensembl/modules );
    my @missing = grep {
        my $want = $_;
        not grep { $_ eq $want } @part
    } @want_part;
    die "Ensembl v$ensembl_version is missing components (@missing)" if @missing;

    return @lib;
}


=head1 AUTHOR

mca@sanger.ac.uk

=cut

1;
