#!/usr/bin/perl
# Copyright [2018-2023] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


## Parse google scholar headers from DOI
##
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2013-06-24 08:19:22 +0100 (Mon, 24 Jun 2013) $
## Revision       : $Revision: 805 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/google-scholar-parser.pl $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use LWP::Simple qw(get);
use Data::Dumper qw(Dumper);

foreach my $doi ( @ARGV ) {
  my $ref = process($doi);
  print Dumper( $ref ); ## no critic (RequireChecked)
}

sub process {
  my $doi = shift;
  my @html = grep { m{\Ameta}mxs } split m{<}mxs, get 'http://dx.doi.org/'.$doi;
  my $reference = { 'doi' => $doi };
  my %simple_map = qw(pmid pubmed doi doi issn issn isbn issn title title);
  my @authors;
  my $pub = { map {$_=>undef} qw(
    issue firstpage lastpage volume journal_title publication_date online_date
    conference_title dissertation_institution technical_report_institution
    technical_report_number date authors inbook_title
  )};

  foreach ( @html ) {
    my ($k,$v);
    ## no critic (ComplexRegexes)
    if( m{meta\s+(?:.*?\s+)?name="citation_(\w+)"\s+content="\s*(.*?)\s*"}mxs ) {
      $k = $1;
      $v = $2;
    } elsif( m{meta\s+(?:.*?\s+)?content="\s*(.*?)\s*"\s+name="citation_(\w+)"}mxs ) {
      $k = $2;
      $v = $1;
    } else {
      next;
    }
    ## use critic
    if( exists $simple_map{ $k } ) {
      $reference->{$simple_map{$k}}=$v;
    } elsif( exists $pub->{$k} ) {
      $pub->{$k} = $v;
    } elsif( $k eq 'author' ) {
      push @authors, $v;
    }
  }

  my $pub_date = $pub->{'publication_date'} || $pub->{'online_date'} || $pub->{'date'}, q(-);

  $reference->{'publication'} = sprintf '%s %s; %s',
    $pub->{'journal_title'}||$pub->{'conference_title'} || $pub->{'inbook_title'} || q(-),
    $pub_date =~ m{(\d{4})}mxs ? $1: q(-),
    join q(),
      $pub->{'volume'} ? "$pub->{'volume'};" : q(),
      $pub->{'issue'}  ? "$pub->{'issue'};"  : q(),
      $pub->{'firstpage'}||q(),
      $pub->{'lastpage'} ? "-$pub->{'lastpage'}":q(),
    ;
  $reference->{'author_list'} = join q(, ), @authors;
  $reference->{'author_list'} = $pub->{'authors'} if exists $pub->{'authors'} && !@authors;
  $reference->{'pub_date'}    = $pub_date;

  return $reference;
}

1;
