#!/usr/bin/perl

## Generate code...
## Author         : js5
## Maintainer     : js5
##   created        : 2009-08-12
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use English qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);
use Time::HiRes qw(time);
use Getopt::Long qw(GetOptions);

my $ROOT_PATH;

BEGIN {
  $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME)));
}

use lib "$ROOT_PATH/lib";
use Pagesmith::Utils::CodeWriter::Factory;

my $force = 0;
my $root = $ROOT_PATH;

GetOptions( 'force' => \$force, 'root=s' => \$root );

my $cwf = Pagesmith::Utils::CodeWriter::Factory->new( $root, $force );

my $time = time;

$cwf->header( 'Building objects and their adaptors...' );

foreach my $filename ( @ARGV ) {
  my $conf = $cwf->load_config( $filename );

  $cwf->header( $filename );

  unless( $conf ) {
    $cwf->blank->msg( ' **ERROR** ', $filename, '- unable to read file' );
    next;
  }

  $cwf->header(  '-Schema' );
    $cwf->created_msg( $cwf->schema->create             );

  $cwf->header(  '-Support' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->support->base_class        );
    $cwf->header(  '--Script class' );
      $cwf->created_msg( $cwf->support->script_base_class        );

  $cwf->header(  '-Objects' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->object->base_class         );
    $cwf->header(  '--Models' );
      $cwf->created_msg( $cwf->object->create(       $_ ) ) foreach $cwf->objecttypes;

  $cwf->header(  '-Adaptors' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->adaptor->base_class        );
    $cwf->header(  '--Object adaptors' );
      $cwf->created_msg( $cwf->adaptor->create(      $_ ) ) foreach $cwf->objecttypes;
    $cwf->header(  '--Relationship adaptors' );
      $cwf->created_msg( $cwf->relationship->create( $_ ) ) foreach $cwf->relationships;
    $cwf->header(  '--Secure classes' );
  foreach ( $cwf->adaptor->secure_classes( $cwf->objecttypes ) ) {
    $cwf->created_msg( $_ );
  }

  $cwf->header(  '-Components' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->component->base_class      );
    $cwf->header(  '--Admin page components' );
      $cwf->created_msg( $cwf->component->admin(     $_ ) ) foreach $cwf->objecttypes;

  $cwf->header(  '-Actions' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->action->base_class         );
    $cwf->header(  '--Admin page wrapper' );
      $cwf->created_msg( $cwf->action->admin_wrapper      );
    $cwf->header(  '--Admin page actions' );
      $cwf->created_msg( $cwf->action->admin(        $_ ) ) foreach $cwf->objecttypes;

  $cwf->header(  '-Forms' );
    $cwf->header(  '--Base class' );
      $cwf->created_msg( $cwf->form->base_class           );
    $cwf->header(  '--Admin page forms' );
      $cwf->created_msg( $cwf->form->admin(          $_ ) ) foreach $cwf->objecttypes;
}

$cwf->blank->msg( '** Completed in '.(time-$time).' seconds **' );
$cwf->blank->blank;

1;

__END__

Development notes:
==================

The following has to be completed

Pagesmith::CodeWriter::Schema
-----------------------------

* Adding in code to talk to "dictionary tables"

Pagesmith::CodeWriter::Support
------------------------------

* [done/doc] Table code
* [done/doc] Adaptor code

Pagesmith::CodeWriter::Object
-----------------------------

* [done/...] Get setters
* [..../...] Dictionary code 1 get/setters
* [..../...] Dictionary code many get/clear/add/remove/set code
* [..../...] Has 1 get/setters
* [..../...] Has many get/clear/add/remove/set code
* [..../...] Relationship get setters...
* [done/...] Store method

Pagesmith::CodeWriter::Adaptor
------------------------------

* [done/doc] Fetch 1/fetch all
* [..../...] Fetch all by
* [..../...] Adding in lookup columns....
* [..../...] Store/Update
* [..../...] Storing lookup column values...
* [..../...] Audit columns for store/update

Pagesmith::CodeWriter::Relationship
-----------------------------------

* [done/doc] Fetchers - 1 row, all, subsets
* [done/   ] Store/update
* [..../...] Audit columns for store/update

Pagesmith::CodeWriter::Component
------------------------------

* [done/doc] "Core" module
* [done/doc] Admin table modules
* [..../...] Reduce table column count...

Pagesmith::CodeWriter::Action
------------------------------

* [done/doc] "Core" module
* [done/doc] Core admin wrapper module


Pagesmith::CodeWriter::Form
------------------------------

* [..../...] "Core" module
* [..../...] Form view for each object
* [..../...] Auto-completer code for auto-complete columns...
* [..../...] Get values from object
* [..../...] Store values to object...
