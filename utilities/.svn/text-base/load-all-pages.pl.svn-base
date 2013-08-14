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

use English qw(-no_match_vars $PROGRAM_NAME $EVAL_ERROR);
use File::Basename qw(dirname basename);
use Cwd qw(abs_path);
use Const::Fast qw(const);
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time sleep);

# Define constants and data-structures

const my $URL_MAX_LENGTH => 120;
const my $SLEEP_PERIOD   => 0.001;
const my $RATE           => 5;
const my $TIME_OUT       => 60;
const my $MAX_TRIES      => 5;

my $ROOT_PATH;
BEGIN { $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME))); }
use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::Core;
use Pagesmith::Utils::Curl::Fetcher;
use Pagesmith::Utils::Curl::Request;

my $host       = q();
my $branch     = 'live';
my $help       = 0;
my $repos_name = q();
my $ajax       = 0;
my $flush      = 0;
my $rate       = $RATE;
my $time_out   = $TIME_OUT;
my $max_tries  = $MAX_TRIES;
my $repos_root;
my $xhtml      = 0;

my @headers;
my @cookies;

GetOptions(
  'help'          => \$help,
  'site=s'        => \$host,
  'branch=s'      => \$branch,
  'repos=s'       => \$repos_name,
  'root=s'        => \$repos_root,
  'flush+'        => \$flush,
  'ajax'          => \$ajax,
  'concurrency=i' => \$rate,
  'timeout=i'     => \$time_out,
  'maxtries=i'    => \$max_tries,
  'xhtml'         => \$xhtml,
);

_docs() if $help || $host eq q();

push @cookies, 'PageSmith=%7B%22a%22%3A%22e%22%7D' if $ajax;
push @headers, 'Pragma: no-cache'                  if $flush;
push @headers, $xhtml ? 'Accept: text/html,application/xhtml+xml,application/xml' : 'Accept: text/html';

( my $repos  = $host ) =~ s{[.]}{-}mxsg;

$repos = $repos_name if $repos_name;

my $support = Pagesmith::Utils::Core->new();

unless( $repos_root ) {
  my @out = $support->read_from_process( 'svn', 'info', q(.) );
  foreach( @out ) {
    my ($k,$v) = split m{:\s+}mxs, $_, 2;
    next unless $k;
    if( $k eq 'Repository Root' ) {
      ( $repos_root = $v ) =~ s{/[^/]+\Z}{}mxs;
    }
  }
}

my @urls;
my $rv = eval {
  my @out = $support->read_from_process( 'svn', 'list', '-R',
    sprintf '%s/%s/%s/htdocs', $repos_root, $repos, $branch);
  my @pages = grep { m{[.]html\Z}mxs } @out;
  my @externals = $support->read_from_process( 'svn', 'propget', 'svn:externals',
      sprintf '%s/%s/%s/htdocs', $repos_root, $repos, $branch);
  foreach my $ext (@externals) {
    next unless $ext;
    my ($d, $r) = split m{\s+}mxs, $ext;
    my @ext_out = $support->read_from_process( 'svn', 'list', '-R', $r );
    push @pages, map { "$d/$_" } grep { m{[.]html\Z}mxs } @ext_out;
  }
  foreach( @pages ) {
## We have a web page to get...
    s{\A(|.*/)index[.]html\Z}{$1}mxs;
    push @urls, sprintf 'http://%s/%s', $host, $_;
  }

};

die "No static pages found - do you have a valid repository!\n" unless @urls;

if( $flush > 1 ) { ## If two "-f" switches then we flush the template as well!
  _fetch( {
    'rate'    => 1,
    'urls'    => [ shift @urls ],
    'cookies' => \@cookies,
    'headers' => [ 'X-Flush-Cache: templates', @headers ],
    'timeout' => $time_out,
  } );
}
## Now fetch all pages...
_fetch( {
  'rate'    => $rate,
  'urls'    => \@urls,
  'cookies' => \@cookies,
  'headers' => \@headers,
  'timeout' => $time_out,
});

sub _fetch {
  my( $params ) = @_;
  my $c    = Pagesmith::Utils::Curl::Fetcher->new();
  my $init = time;
  my $failed_urls = {};
  ## no critic (LongChainsOfMethodCalls)
  foreach( 1..$params->{'rate'}) {
    last unless @{$params->{'urls'}};
    $c->add( Pagesmith::Utils::Curl::Request->new( shift @{$params->{'urls'}} )
        ->set_cookies( $params->{'cookies'} )
        ->set_headers( $params->{'headers'} )
        ->set_timeouts( $params->{'timeout'} )
        ->init );
  }

  my $out = 0;

  while( $c->has_active ) {
    next if $c->active_transfers == $c->active_handles;
    while( my $req = $c->next_request ) {
      $out++;
      my $end = time;
      printf "%2d %9.6f %9.6f %8d %8d %3d %7d %7d %s\n",
        $failed_urls->{ $req->url }   || 0,
        ($end-$init)                  || 0,
        ($end-$req->start_time)       || 0,
        $req->curl_id                 || 0,
        $out                          || 0,
        $req->response->code          || 0,
        $req->response->content_length|| 0,
        length $req->response->body   || 0,
        substr $req->url, 0, $URL_MAX_LENGTH
      ;
      unless( $req->response->code ) {
        push @{$params->{'urls'}}, $req->url if $failed_urls->{ $req->url }++ < $MAX_TRIES;
      }
      $c->remove( $req );
      ## Retry a URL if failed with timeout!
      next unless @{$params->{'urls'}};
      ## If we have any more URLs add the new one!
      $c->add( Pagesmith::Utils::Curl::Request->new( shift @{$params->{'urls'}} )
        ->set_cookies( $params->{'cookies'} )
        ->set_headers( $params->{'headers'} )
        ->set_timeouts( $params->{'timeout'} )
        ->init );
      sleep $SLEEP_PERIOD;
    }
  }
  return;
}
## use critic
sub _docs {
  ## no critic (ImplicitNewlines CheckedSyscalls)
  print '
Loads all "static" pages on the domain (or at least those that are delivered from svn)

utilities/load-all-pages.pl
  -h|--help
  -s|--site        {domain_name}
  -b|--branch      (trunk|staging|live)
  -r|--repos       {repos_name}
  -f|--flush
  -a|--ajax
  -c|--concurrency {rate}
  -m|--maxtries    {no}
  -t|--timeout     {seconds}

Options:
  -h, --help        : Display this message
  -s, --site        : Site domain name e.g www.gencodegenes.org : REQUIRED
  -b, --branch      : Branch name (one of trunk, staging, live) : default live
  -r, --repos       : Repository name : defaults to sitename with . replaced by -
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
