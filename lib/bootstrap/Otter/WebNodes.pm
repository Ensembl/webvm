package Otter::WebNodes;
use strict;
use warnings;


=head1 NAME

Otter::WebNodes - model of what machines are where

=head1 DESCRIPTION

Fixups and convenience on top of L<Otter::WebConfig>, e.g. "what is
the URL of each live backend?"

=cut

use Otter::WebConfig 'config_extract';
use Otter::Paths;

use URI;
use Carp;
use Try::Tiny;

my ($DOMAIN, %PORT);
__init();

=head1 CLASS METHODS

=head2 new(%prop)

An indiscriminate constructor.

=cut


sub new {
    my ($pkg, @arg) = @_;
    my $self = { @arg };
    bless $self, $pkg;
    return $self;
}


=head2 new_cgi($cgi)

Construct one object which (closely enough) represents the current
virtual host, as viewed by L<CGI>.

C<$cgi> is optional.  If the method instantiates one it could eat your
POST data.

=cut

sub new_cgi {
    my ($pkg, $cgi) = @_;

    # Caller needs to find some server, we can't (probably shouldn't) help
    croak "Cannot construct new_cgi outside a CGI script"
      unless $ENV{GATEWAY_INTERFACE};

    $cgi ||= CGI->new;

    my $webdir = Otter::Paths->webdir;
    my $tmpdir =
      (($webdir =~ m{^(/www)(/.+)$})
       ? "$1/tmp$2" # works for webteam VMs
       : undef); # can't guess, ->fillin will fail

    my %new =
      (vhost => $cgi->virtual_host,
       vport => $cgi->virtual_port,
       webdir => $webdir,
       webtmpdir => $tmpdir,
       provenance => 'new_cgi',
#       type # unknown, will calculate
      );

    # Heuristic from observed %ENV
    my @not_in_env = grep { !defined $ENV{$_} }
      qw( HTTP_X_CLUSTER_CLIENT_IP HTTP_X_FORWARDED_SERVER HTTP_X_IS_SSL );

    $new{frontend} = 1 # haven't figured out what for
      if (0 == @not_in_env);

    return $pkg->new(%new);
}


=head2 listnew_config()

Construct objects from L<Otter::WebConfig> and return them in a list.

Some items may be missing from the list, or not real (there is no
fixup).

This doesn't include user sandboxes, because it is generated from
"places that www-core will allow someone to access files" config; nor
frontends, which are configured elsewhere.

=cut

sub listnew_config {
    my ($pkg) = @_;
    croak "wantarray!" unless wantarray;

    my $raw = config_extract(undef, 1);
    return map {
        my %new = (provenance => 'config',
                   frontend => 0);
        @new{qw{ vhost type webdir webtmpdir }} =
          @{$_}{qw{ hostname type write read }};
        $new{vhost} .= $DOMAIN;

        $pkg->new(%new);
    } @$raw;
}


=head2 listnew_sandboxes()

Attempt to construct a list of developer sandbox Apaches, plus their
front-end URLs.

=cut

sub listnew_sandboxes {
    my ($pkg) = @_;

    my @out;
    foreach my $user (keys %PORT) {
        next if $user eq 'www-core'; # has no sandboxes
        my %back =
          (vhost => 'web-ottersand-01'.$DOMAIN, # assuming just one
           type => 'sandbox',
           webdir => "/www/$user/www-dev",
           webtmpdir => "/www/tmp/$user/www-dev",
           provenance => 'listnew_sandboxes',
           user => $user,
           frontend => 0);
        my @back = ($pkg->new(%back));

        my $front = $pkg->_front4("$user-otter.sandbox.sanger.ac.uk", @back);
        $$front{user} = $user;

        push @out, @back, $front;
    }

    return @out;
}


=head2 listnew_fixed()

Starting with L</listnew_config>, attempt to construct a complete set
of valid backend and frontend nodes.

Currently doesn't attempt to construct a frontend node of C<type =>
'live'> because there probably isn't one with 1:1 URL mapping, and
there is not yet a way to mark "only serves a few nominated URLs".

=cut

sub listnew_fixed {
    my ($pkg) = @_;
    croak "wantarray!" unless wantarray;

    my @cfg = $pkg->listnew_config;
    my @back = @cfg;

    # Discover other @back by enumeration in DNS
    my %model; # key = base, value = [ num, srv, dom ]
    foreach my $srv (@cfg) {
        my ($base, $num, $dom) = $srv->vhost =~ m{^([^.]+?)(\d+)(\..*|$)};
        next unless defined $base;
        next if defined $model{$base}[0] &&
          $num lt $model{$base}[0]; # avoid downgrading to numbers
        $model{$base} = [ $num, $srv, $dom ];
    }
    while (my ($base, $v) = each %model) {
        my ($num, $srv, $dom) = @$v;
        my @more_host = grep { $_ ne "$base$num" } __dns_enumerate($base, $num);

        # Clone, but different vhost
        foreach my $hostname (@more_host) {
            my %new = %$srv;
            $new{vhost} = "$hostname$dom";
            $new{provenance} .= '>dns_enumerate';
            push @back, $pkg->new(%new);
        }
    }

    # Exclude those which are not real
    @back = grep { __valid_host($_->vhost) } @back;

    # Construct known front-ends
    my @front;
    foreach my $type (qw( live staging dev )) {
        # not expected for live
        # sandbox are found separately
        my $part = $type eq 'live' ? '' : ".$type";
        push @front, $pkg->_front4("otter$part.sanger.ac.uk",
                                   grep { $_->type eq $type } @back);
    }

    my @sand = $pkg->listnew_sandboxes;

    # Sort, assuming already uniq
    my @out = (@back, @front, @sand);
    @out = sort {( ($a->type cmp $b->type) ||
                   ($a->vhost cmp $b->vhost) ||
                   ($a->vport <=> $b->vport) )} @out;
    return @out;
}

sub __dns_enumerate {
    my ($base, $sfx) = @_;

    my @out;
    while (1) { # exits with last
        my $try = "$base$sfx";
        $sfx ++;

        if (__valid_host("$try$DOMAIN")) {
            # it's valid
            push @out, $try;
        } else {
            last;
        }
    }

    return @out;
}

sub __valid_host {
    my ($name) = @_;

    my $packed_ip = gethostbyname($name);
#    print Dump({ gethostbyname => { query => $name, packed_ip => $packed_ip } }) if $opt{debug};
    return defined $packed_ip;
}


sub _front4 {
    my ($pkg, $vhost, @back) = @_;
    return () unless @back;

    my $prov = $back[0]->provenance;
    my %new =
      (vhost => $vhost,
       vport => 80,
       type => $back[0]->type,
       # user, webdir, webtmpdir : undef, will error
       provenance => "_front4($prov)",
       frontend => [ map { $_->base_uri } @back ]);

    return $pkg->new(%new);
}


sub __init {
    # XXX: Could look up port numbers in ServerRoot/conf/user/*.conf
    # "Listen" lines but they are fairly static.
    %PORT = (
        'www-core' => 8000,
        'jgrg'     => 8001,
        'mg13'     => 8004,
        'zmap'     => 8005,
        'edgrif'   => 8006,
        'gb10'     => 8007,
        'sm23'     => 8008,
        );

    $DOMAIN = '.internal.sanger.ac.uk';

    return;
}


=head1 OBJECT METHODS

=head2 vhost, webdir, webtmpdir

Read accessors.  If there is no data, they generate an error; unless a
true argument is given, then they return undef.

=cut

foreach my $key (qw( vhost webdir webtmpdir )) {
    my $code = sub {
        my ($self, $force) = @_;
        if (!$force && !defined $$self{$key}) {
            my $prov = $self->provenance;
            my $h = $$self{vhost} || '?';
            my $p = $$self{vport} || '?';
            croak "No $key was set ($h:$p provenance=$prov)";
        }
        return $$self{$key};
    };
    no strict 'refs';
    *{__PACKAGE__.'::'.$key} = $code;
}


=head2 vport()

Read accessor.  Returns the value, or a guess, or an error if it
cannot guess.

=cut

sub vport {
    my ($self) = @_;
    if (defined $$self{vport}) {
        return $$self{vport};
    } elsif (my $port = $self->_webdir2port) {
        return $port;
    } else {
        my $prov = $self->provenance;
        croak "Cannot guess port for vhost=$$self{vhost} provenance=$prov";
    }
}

sub _webdir2port {
    my ($self) = @_;
    my $user = $self->user;
    return $PORT{$user} or croak "Cannot get port number for user $user";
}


=head2 user()

Read accessor.  Returns the user owning & running the node, if it is
known or can be deduced.  Otherwise generates an error.

=cut

sub user {
    my ($self) = @_;
    my $d = $self->webdir;
    if (defined $$self{user}) {
        return $$self{user};
    } elsif ($d =~ m{^/www/([-a-z0-9]+)/www-dev(?:$|/)}) {
        return $1;
    } elsif ($d =~ m{^/www/www-(dev|live)(?:$|/)}) {
        return 'www-core';
    } else {
        croak "Cannot deduce user from webdir=$d provenance=$$self{provenance}";
    }
}


=head2 type()

Read accessor.  Returns one of C<qw( sandbox dev staging live )>,
including for frontend URLs.

Unrecognised hosts are assumed to be non-webteam sandboxes.

=cut

sub type {
    my ($self) = @_;
    if (defined $$self{type}) {
        return $$self{type};
    } elsif ($self->vhost =~ m{^web-otter(sandbox|staging|dev|live)-?\d}) {
        return $1;
    } elsif ($self->vhost =~ m{\.(sandbox|staging|dev)\.sanger\.ac\.uk$}) {
        return $1;
    } elsif ($self->vhost =~ m{^(otter|www)\.sanger\.ac\.uk$}) {
        # www. : unlikely
        return 'live';
    } else {
        return 'sandbox';
    }
}


=head2 provenance()

Read accessor.  Tells what instantiated this (possibly C<unknown>).

=cut

sub provenance {
    my ($self) = @_;
    return $$self{provenance} || 'unknown';
}


=head2 base_uri()

Returns a L<URI> constructed from L</vhost> and L</vport>.

=cut

sub base_uri {
    my ($self) = @_;
    my ($h, $p) = ($self->vhost, $self->vport);
    return URI->new("http://$h:$p")->canonical;
}


=head2 display_name()

Some kind of short name.

=cut

sub display_name {
    my ($self) = @_;
    my $host = $self->vhost;
    $host =~ s{(?:\.internal)?\.sanger\.ac\.uk$}{~};
    $host =~ s{^web-otter(.+?)-?(\d+)~$}{~$1$2~};
    my $user = $self->is_frontend ? '' : $self->user;
    $user = $user =~ /^(www-core|)$/ ? '' : $user.'@';
    return $user.$host;
}


=head2 is_frontend()

Read accessor.  Return true if the vhost is a front-end proxy
(i.e. ZXTM).  This may be a guess.

=cut

sub is_frontend {
    my ($self) = @_;
    if (defined $$self{frontend}) {
        return $$self{frontend} ? 1 : 0;
    } elsif ($self->vhost =~ m{^web-otter(sandbox|staging|dev|live)-?\d}) {
        return 0;
    } elsif ($self->vhost =~ m{\.(sandbox|staging|dev)\.sanger\.ac\.uk$}) {
        return 1;
    } elsif ($self->vhost eq 'www.sanger.ac.uk') {
        return 1;
    } else {
        return 0;
    }
}


=head2 frontend_contains($back)

Return true iff this is a frontend which covers all URLs of the
backend object C<$back>.

=head2 frontend_contains()

Return a list of (copies of) the backend L<URI>s to which this
frontend maps.

=cut

sub frontend_contains {
    my ($self, $back) = @_;
    return () unless $self->is_frontend;

    my $fe = $$self{frontend};
    if (ref($fe) ne 'ARRAY') {
        my $prov = $self->provenance;
        croak "Frontend (provenance=$prov) reverse proxied list is absent";
    }

    if (defined $back) {
        my $want_base = $back->base_uri;
        return 1 if grep { $_ eq $want_base } @$fe;
        return 0;
    } else {
        my @back = map { $_->clone } @$fe;
        return @back;
    }
}


=head2 fillin()

A bodge to make most of the read-accessor properties explicit in the
hash, so the object can be serialised and the reader doesn't need this
class.

=cut

sub fillin {
    my ($self) = @_;

    my @prop = (qw( vhost vport provenance type ),
                qw( base_uri is_frontend display_name )); # derived
    push @prop, qw( user webdir webtmpdir ) unless $self->is_frontend;

    foreach my $prop (@prop) {
        $$self{$prop} = $self->$prop;
    }

    return $self;
}

1;
