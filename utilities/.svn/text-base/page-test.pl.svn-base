#!/usr/bin/perl

## Look in SVN for all static content pages (.html) and then use CURL to request them all
##
##
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use HTML::Entities qw(encode_entities);

use English qw(-no_match_vars $PROGRAM_NAME $EVAL_ERROR $INPUT_RECORD_SEPARATOR);
use File::Basename qw(dirname basename);
use Cwd qw(abs_path);
use Readonly qw(Readonly);
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time sleep);
use YAML::Loader;
use Data::Dumper qw(Dumper);

# Define constants and data-structures

Readonly my $URL_MAX_LENGTH => 120;
Readonly my $SLEEP_PERIOD   => 0.001;
Readonly my $RATE           => 5;
Readonly my $TIME_OUT       => 60;
Readonly my $MAX_TRIES      => 5;

my $ROOT_PATH;
BEGIN { $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME))); }
use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::Core;
use Pagesmith::Utils::Curl::Fetcher;

my $help       = 0;
my $ajax       = 0;
my $flush      = 0;
my $rate       = $RATE;
my $time_out   = $TIME_OUT;
my $max_tries  = $MAX_TRIES;
my $xhtml      = 0;
my $verbose    = 0;
my $local      = 0;
my $dev        = 0;
my $staging    = 0;

my @headers;
my @cookies;

GetOptions(
  'help'          => \$help,
  'flush+'        => \$flush,
  'ajax'          => \$ajax,
  'concurrency=i' => \$rate,
  'timeout=i'     => \$time_out,
  'maxtries=i'    => \$max_tries,
  'verbose+'      => \$verbose,
  'xhtml'         => \$xhtml,
  'local'         => \$local,
  'dev'           => \$dev,
  'staging'       => \$staging,
);

my $type_to_test = $staging ? 'staging'
                 : $dev     ? 'dev'
                 : $local   ? 'local'
                 :            'live'
                 ;

_docs() if $help;

push @cookies, 'PageSmith=%7B%22a%22%3A%22e%22%7D' if $ajax;
push @headers, 'Pragma: no-cache'                  if $flush;
push @headers, $xhtml ? 'Accept: text/html,application/xhtml+xml,application/xml' : 'Accept: text/html';

my %return_vals;
my @urls;

if( opendir my $dh, "$ROOT_PATH/sites" ) {
  my @sites_list = grep { ! m{\A[.]}mxs && -e "$ROOT_PATH/sites/$_/data/urls" } readdir $dh;
  closedir $dh;
  _get_urls( \%return_vals, \@urls, @sites_list );
} else {
  die "Unable to open sites directory...\n";
}

_munge_urls( $type_to_test, \@urls, \%return_vals ) unless $type_to_test eq 'live';

my $start_time = time;

_fetch( {
  'rate'    => $rate,
  'urls'    => \@urls,
  'cookies' => \@cookies,
  'headers' => \@headers,
  'timeout' => $time_out,
});
## no critic (ImplicitNewlines)
printf '
--------------------------------------
Total: %10.3f
--------------------------------------
', time-$start_time if $verbose > 1;
## use critic

## no critic (DeepNests ExcessComplexity)
sub _munge_urls {
  my( $type, $urls, $ret_vals ) = @_;
  my $local_sites = {};
  $local_sites = get_yaml( "$ROOT_PATH/my-sites.yaml" ) if $type eq 'local';
  my $apache = get_apache_sites( "$ROOT_PATH/apache2/sites-enabled" );
  my $mapper = {};
  my @new_urls;
  foreach my $url (@{$urls}) {
    if( $url =~m{\A(https?)://([^/]+)(/.*)}mxs ) {
      my( $protocol, $site, $rest ) = ($1,$2,$3);
      unless( exists $mapper->{$site} ) {
        if( $type eq 'local' ) {
          foreach my $local ( sort keys $local_sites ) {
            if( exists $apache->{$local} && $apache->{$local}[1] eq $site ) {
              $mapper->{$site} = $local;
              last;
            } else {
              ( my $munged = $local ) =~ s{\A\w+-}{*-}mxs;
              if( exists $apache->{$munged} && $apache->{$munged}[1] eq $site ) {
                $mapper->{$site} = $local;
                last;
              }
            }
          }
        } else {
          foreach my $s (sort keys %{$apache}) {
            next unless index $s, q(*);
            my $reg = '\A(?:\w+[.])?'.$type.'[.]';
            if( $s =~ m{$reg}mxs && $apache->{$s}[1] eq $site ) {
              $mapper->{$site} = $s;
              last;
            }
          }
        }
      }
      $mapper->{$site}||=q();
      unless( $mapper->{$site} ) {
        printf "-skip:            : %s\n", $url if $verbose > 1;
        next;
      }
      my $new_url = "$protocol://$mapper->{$site}$rest";
      push @new_urls, $new_url;
      next if $new_url eq $url;
      $ret_vals->{$new_url} = $ret_vals->{$url};
      delete $ret_vals->{$url};
    }
  }
  @{$urls} = @new_urls;
  return;
}
## use critic

sub _get_urls {
  my ($ref_ret, $ref_urls, @sites) = @_;
  foreach my $site ( @sites ) {
    my $dirname = "$ROOT_PATH/sites/$site/data/urls";
    my $dh;
    unless( opendir $dh, $dirname ) {
      next;
    }
    my @files = grep { ! m{\A[.]}mxs && m{https?(?:-\S+)?[.]txt\Z}mxs } readdir $dh;
    foreach my $file (@files) {
      my ($protocol,$site_name) = $file =~ m{\A(https?)(?:-(\S+))?[.]txt}mxs ? ($1,$2) : ($file);
      $site_name ||= $site;
      my @url_details;
      if( open my $fh, q(<), "$dirname/$file" ) {
        @url_details = grep { m{\S}mxs && ! m{\A\s*[#]}mxs } <$fh>;
        close $fh; ## no critic (RequireChecked)
      } else {
        next;
      }
      chomp @url_details;
      my $det = shift @url_details;
      while( $det || @url_details ) {
        my( $url, $code ) = split m{[ ]}mxs, $det;
        $code ||= q(200);
        unless( $url ) {
          $det = shift @url_details;
          next;
        }
        $url = "$protocol://$site$url" unless $url =~ m{\Ahttps?://}mxs;
        push @{$ref_urls}, $url;
        $ref_ret->{ $url } = [ $code ];
        $det = shift @url_details;
        while( defined $det && ! index $det, q( ) ) {
          $det =~ s{\A\s+}{}mxs;
          push @{$ref_ret->{$url}}, $det;
          $det = shift @url_details;
        }
      }
    }
  }
  return;
}


## no critic (ExcessComplexity DeepNests)
sub _fetch {
  my( $params ) = @_;
  my $c    = Pagesmith::Utils::Curl::Fetcher->new();
  my $init = time;
  my $failed_urls = {};
  my $start       = {};
  ## no critic (LongChainsOfMethodCalls)
  foreach( 1..$params->{'rate'}) {
    last unless @{$params->{'urls'}};
    my $url = $c->new_request( shift @{$params->{'urls'}} )
        ->set_cookies( $params->{'cookies'} )
        ->set_headers( $params->{'headers'} )
        ->set_timeouts( $params->{'timeout'} )
        ->init->url;
    next if $verbose <= 1;
    $start->{$url} = time;
    printf "-----:            : %s\n", $url;
  }

  my $out = 0;

  while( $c->has_active ) {
    next if $c->active_transfers == $c->active_handles;
    while( my $req = $c->next_request ) {
      $out++;
      my $end = time;
      my $rc = $req->response->code;
      my ($exp_rc,@exp_content) = @{$return_vals{$req->url}};
      if( $rc ) {
        delete $failed_urls->{ $req->url };
        if( $exp_rc == $rc ) {
          (my $content = $req->response->body) =~ s{\s+}{ }mxsg;
          my $extra = $verbose > 1 ? sprintf ' %10.3f :', time-$start->{$req->url} : q();
          printf "Match:%s %s\n", $extra, $req->url if $verbose;
          foreach my $exp ( @exp_content ) {
            if( 0 <= index $content, $exp ) {
              printf " Good:%s %s (%s)\n", $extra, $req->url, $exp if $verbose;
            } else {
              printf "  Bad:%s %s (%s)\n", $extra, $req->url, $exp;
            }
          }
        } else {
          my $extra = $verbose > 1 ? sprintf ' %10.3f :', time-$start->{$req->url} : q();
          printf "Error:%s %s [ %d != %d ]\n", $extra, $req->url, $rc, $exp_rc;
        }
      } else {
        push @{$params->{'urls'}}, $req->url if $failed_urls->{ $req->url }++ < $max_tries;
      }
      $c->remove( $req );
      ## Retry a URL if failed with timeout!
      next unless @{$params->{'urls'}};
      ## If we have any more URLs add the new one!
      my $url = $c->new_request( shift @{$params->{'urls'}} )
          ->set_cookies( $params->{'cookies'} )
          ->set_headers( $params->{'headers'} )
          ->set_timeouts( $params->{'timeout'} )
          ->init->url;
      if( $verbose > 1 ) {
        printf "-----:            : %s\n", $url;
        $start->{$url} = time;
      }
      sleep $SLEEP_PERIOD;
    }
  }
  foreach ( sort keys %{$failed_urls} ) {
    printf "Fatal:            : $_\n";
  }
  return;
}
## use critic
sub _docs {
  ## no critic (ImplicitNewlines CheckedSyscalls)
  print '
Loads a list of URLS from a file...

utilities/load-all-pages.pl
  -h|--help
  -f|--flush
  -a|--ajax
  -c|--concurrency {rate}
  -m|--maxtries    {no}
  -t|--timeout     {seconds}

Options:
  -h, --help        : Display this message
  -f, --flush       : Send flush page header
                    : If TWO -f are supplied flush template as well
  -a, --ajax        : Send ajax cookie - so ajax page is cached
  -m, --maxtries    : Max no of times to try each url if timed out...
  -c, --concurrency : Concurrency  : default 5
  -t, --timeout     : cURL timeout : default 60 seconds

';
  ## use critic
  exit;
}
## use critic

sub get_yaml {
  my $filename = shift;
  if( open my $fh, '<', $filename ) {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $contents = <$fh>;
    close $fh; ## no critic (RequireChecked)
    my $yl   = YAML::Loader->new;
    my $hash = eval { $yl->load( $contents ); };
    if( $EVAL_ERROR ) {
      warn "YAML error $filename - $EVAL_ERROR\n";
      return;
    }
    return $hash;
  }
  warn "Unable to open config file\n";
  return;
}

sub get_apache_sites {
  my $apache_sites_dir = shift;
  my $dh;
  opendir $dh, $apache_sites_dir;
  return unless $dh;
  my @conf_files = grep { ! m{\A[.]}mxs && ! -d "$apache_sites_dir/$_" } readdir $dh;
  closedir $dh;
  my $domains = {};
  foreach my $fn ( @conf_files ) {
    ## no critic (BriefOpen)
    if( open my $fh, q(<), "$apache_sites_dir/$fn" ) {
      my $server_name;
      my $server_aliases = [];
      my $docroot     = q();
      while(<$fh>) {
        if( m{</VirtualHost>}mxs) {
          if( $server_name ) {
            $domains->{$_} = [ $docroot, $server_name  ] foreach (@{$server_aliases},$server_name);
          }
          $server_name    = undef;
          $server_aliases = [];
          $docroot        = q();
        } elsif( m{\A\s*Server(Name|Alias)\s+(.*?)\s+\Z}mxs ) {
          my ($type,$list) = ($1,$2);
          if( $type eq 'Name' ) {
            $server_name = $list;
          } else {
            push @{$server_aliases}, $_ foreach split m{\s+}mxs, $list;
          }
        } elsif( m{\A\s*DocumentRoot\s*\$[{]PAGESMITH_SERVER_PATH[}]/(\S+)}mxs ) {
          $docroot = $1;
        }
      }
      close $fh; ##no critic (RequireChecked)
    }
    ## use critic
  }
  return $domains;
}

