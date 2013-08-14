#!/usr/bin/perl

## Creates accessor functions and docs for an object
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author: js5 $
## Last modified  : $Date: 2013-04-09 13:50:23 +0100 (Tue, 09 Apr 2013) $
## Revision       : $Revision: 628 $
## Repository URL : $HeadURL: svn+ssh://pagesmith-core@web-wwwsvn.internal.sanger.ac.uk/repos/svn/pagesmith/pagesmith-core/trunk/utilities/create-accessors.pl $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

foreach my $key (sort @ARGV) {
## no critic (ImplicitNewlines InterpolationOfMetachars)
#@raw
  printf q(
sub %1$s {
#@getter
#@self
#@return (String) value of '%1$s'

  my $self = shift;
  return $self->{'%1$s'};
}

sub set_%1$s {
#@setter
#@self
#@%1$s (String) value of '%1$s'
#@return $self

  my( $self, $%1$s ) = @_;
  $self->{'%1$s'} = $%1$s;
  return $self;
}
), $key;
#@endraw
## use critic

}

