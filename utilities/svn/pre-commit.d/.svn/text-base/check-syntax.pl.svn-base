#!/usr/bin/perl

## Updates "dev"
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

use Const::Fast       qw(const);

const my $SELF_FILE => oct 700;
const my $SPACER => "------------------------------------------------------------------------------\n";
const my $WRAP_COLUMNS => 72;
use Carp              qw(croak);
use Config::IniFiles;
use Cwd               qw(abs_path);
use English           qw(-no_match_vars $INPUT_RECORD_SEPARATOR $EVAL_ERROR $PROGRAM_NAME $PID);
use File::Basename    qw(dirname basename);
use File::Path        qw(mkpath rmtree);
use HTML::HeadParser;
use Image::Magick;
use JSON::XS          qw(decode_json);
use Perl::Critic;
use Text::Wrap qw(fill $columns);
use XML::Parser;
use YAML::Loader;

my $ROOT_PATH;
BEGIN {
  $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME)))));
}
use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::SVN::Support;
use Pagesmith::Utils::SVN::Config;
use Pagesmith::Utils::PerlCritic qw(skip);
use Pagesmith::Utils::HTMLcritic;
use Pagesmith::Utils::JScritic;
use Pagesmith::Root;

exit 1 unless @ARGV == 2;

my( $repos, $txn ) = @ARGV;
my $config = Pagesmith::Utils::SVN::Config->new( $ROOT_PATH );
my $support = Pagesmith::Utils::SVN::Support->new;

exit 0 unless $config; ## Can't find config file - let commits go through!
## We are not watching this repository - so we don't need to send anything
exit 0 unless $config->set_repos( $repos );
## User can commit to repository

my( $user, $datestamp, $length, @msg ) = $support->svnlook( 'info', $repos, '-t', $txn );

unless( $config->set_user( $user ) ) {
  $support->send_message( 'User "%s" unable to update repository "%s"', $user, $repos )->clean_up();
  ## User can't perform any action on repository...
  exit 1;
}

my @changed  = $support->svnlook( 'changed',      $repos, '-t', $txn );
my $forcing = @msg && $msg[0] =~ m{\[[\s\w]*(force)[\s\w]*\]}mxs ? 1 : 0;


my %perl_files;

my $exit_status = push_changes( $forcing, $config, $support, @changed );
$exit_status += process_perl_files(  ) if keys %perl_files;
$support->clean_up;
exit $exit_status;

##
## END OF SCRIPT....
##

## no critic (ExcessComplexity)
sub push_changes {
  my ( $l_forcing, $l_config, $l_support, @l_changed ) = @_;
  my $l_exit_status = 0;
  foreach my $line (@l_changed) {
    if( $line =~ m{\A(..)\s*(.*)\Z}mxs ) {
      my( $flags, $filename ) = ($1,$2);

    # The file is a directory - Check to see if the user can adddir in this directory!
      if( $line =~ m{/\Z}mxs && !
        ( $filename =~ m{\Abranches/([-\w]+/)?\Z}mxs && $l_config->can_perform( q(/), 'create_branch' ) )
      ) {
        if( ($flags eq 'D ' || $flags eq 'A ') && ! $l_config->can_perform( "/$filename", 'adddir' ) ) {
          $l_exit_status++;
          $l_support->send_message(
            'User "%s" unable to add/delete directory at "%s" repository "%s"',
            $user, $filename, $repos);
        }
        if( $flags eq 'A ' && $filename =~ m{[[:upper;]]}mxs && $filename !~ m{/lib/}mxs ) {
          $l_exit_status++;
          $l_support->send_message(
            'Directory names must be lower case: "%s"',
            $filename);
        }
        next;
      }

      # Check to see if user can commit this type of file in this location
      if( ($flags eq 'D ' || $flags eq 'A ') && ! $l_config->can_perform( "/$filename", 'addfile' ) ) {
        $l_exit_status++;
        $l_support->send_message(
          'User "%s" unable to add/delete file at "%s" repository "%s"',
          $user, $filename, $repos);
      }

      ## Check to see if file can be editted in this location....
      if( ! $l_config->can_perform( "/$filename", 'update' ) ) {
        $l_exit_status++;
        $l_support->send_message(
          'User "%s" unable to modify file at "%s" repository "%s"',
          $user, $filename, $repos);
      }

      next if $flags eq 'D ' || ## Don't need to syntax checked deleted files!
              $flags eq '_U';   ## Don't need to syntax files for which only properties have changed

      my $sub_info = $l_config->get_method_for( $filename );
      my $force_flag = 1;
         $force_flag = 0 if $l_forcing && $l_config->can_perform( "/$filename", 'force' );
         $force_flag = 0 if $filename =~ m{\A(live|staging)/}mxs;
         $force_flag = 0 if $filename =~ m{\Abranches/([-\w]+/)?\Z}mxs && $l_config->can_perform( q(/), 'create_branch' );
         $force_flag = 0 if $filename =~ m{\Abranches/[-\w]+/.*}mxs    && $l_config->can_perform( q(/), 'branch' );
      no strict 'refs'; ## no critic (NoStrict)
      $l_exit_status += $force_flag && &{$sub_info->{'method'}} ( {
        'repository'  => $repos,
        'filename'    => $filename,
        'transaction' => $txn,
        'flags'       => $flags,
        'extension'   => $sub_info->{'extension'},
      } );
      use strict;
    }
  }
  return $l_exit_status;
}
## use critic;

sub process_perl_files {
## Handle the collected perl files... this will need to be tweaked once we
## have paths setup!
  my $root = Pagesmith::Root->new();
  my $skip = skip();
## we now have list of perl commits, which we wish to look at and checkout...
  my $level = 0;
  my $dirname = '/tmp/'.$root->safe_uuid();
  mkdir $dirname, $SELF_FILE;
## We have created our tmp-lib directory
  my @files_to_check;
  my %extra_errors;
  foreach my $filepath ( sort keys %perl_files ) {
    if( $filepath =~ m{\Atrunk/(.*?)\Z}mxs ) {
      my $file =  $1;
      my $fname = basename( $file );
      my $dname = dirname(  $file );
      mkpath( $dirname.q(/).$dname );
      if( open my $FH, '>', "$dirname/$file" ) {
        print {$FH} $perl_files{$filepath}; ## no critic (RequireChecked)
        close $FH;                          ## no critic (RequireChecked)
        push @files_to_check, "$dirname/$file";
        my $n_tabs  = $perl_files{$filepath} =~ tr{\t}{\t};
        my $n_extra = $perl_files{$filepath} =~ tr{\x00-\x7e}{}c;
        $extra_errors{ "$dirname/$file" } = { 'file' => $file, 'tabs' => $n_tabs, 'other' => $n_extra };
      }
    }
  }
## Prepend our copies of the modules!
  ## Create
  unshift @INC, $dirname;

  foreach my $f ( @files_to_check ) {
    my $message;
    my $res = eval {
      my @viol_critic = Perl::Critic->new( '-severity' => 1 )->critique( $f );
      my $err;
      if( -e 'perltidy.ERR' ) {
        local $INPUT_RECORD_SEPARATOR = undef;
        if( open my $tfh, q(-|), 'touch perltidy.ERR' ) {
          close $tfh; ## no critic (RequireChecked)
        }
        if( open my $fh, q(<), 'perltidy.ERR' ) {
          $err = <$fh>;
          close $fh; ## no critic (RequireChecked)
        }
        unlink 'perltidy.ERR';
      }
      if( $err ) {
        $message .= "  $err\n";
      }
      $message .= sprintf "  Contains %d tab characters\n",       $extra_errors{ $f }{'tabs'}  if $extra_errors{ $f }{'tabs'};
      $message .= sprintf "  Contains %d non-ascii characters\n", $extra_errors{ $f }{'other'} if $extra_errors{ $f }{'other'};
      my $viol_message;
      my $vis_count = 0;
      foreach (@viol_critic) {
        ( my $policy = $_->policy ) =~ s{\APerl::Critic::Policy::}{}mxs;
        next if $skip->{ $policy };
        my($line,$rc,$vc) = @{$_->location};
        my $e = $_->explanation;
        $vis_count++;
        $viol_message .= sprintf "   * %1d : %-60s (%4d,%3d) %s\n", $_->severity, $policy,
          $line,
          $rc,
          $_->description,
          ;
      }
      if( $viol_message ) {
         $message .= sprintf "  Contains %d non-hidden Perl critic violations:\n%s", $vis_count, $viol_message;
      }
    };
    if( $EVAL_ERROR ) {
      $message .= sprintf "  Critic Failed       %s\n `----- %s\n", $f, $EVAL_ERROR;
    }
    if( $message ) {
      $support->send_message( "Unable to commit file '%s' due to errors\n\n%s", $extra_errors{ $f }{'file'}, $message );
      $level++;
    }
  }
  rmtree( $dirname );
  return $level;
}

## Support functions for extension checking methods....

sub _check_non_ascii {
  my( $puh, $html ) = @_;
  my $n_tabs  = $html =~ tr{\t}{\t};
  my $n_extra = $html =~ tr{\x00-\x7e}{}c;

  $puh->push_message( { 'level' => 'Error', 'line' => 0, 'column' => 0,
    'messages' => [ "Contains $n_tabs TABs" ] } )                         if $n_tabs;
  $puh->push_message( { 'level' => 'Error', 'line' => 0, 'column' => 0,
    'messages' => [ "Contains $n_extra non-ascii characters" ] } )        if $n_extra;
  return;
}

sub get_contents {
  my $params = shift;
  return $support->svnlook( 'cat', $params->{'repository'}, $params->{'filename'}, '-t', $params->{'transaction'} );
}

sub dump_messages {
  my( $flag, $puh, $filename ) = @_;
  return 0 unless $flag || $puh->n_errors || $puh->n_warnings || $puh->xml_error;

  printf {*STDERR} "%sUnable to commit file %s\n%s", $SPACER,$filename,$SPACER;
  printf {*STDERR} "MSG: %s\n\n", $flag if $flag;

  foreach( $puh->messages ) {
    printf {*STDERR} "  %-10s : row %4d : col %4d : %s\n",
      $_->{'level'}, $_->{'line'}, $_->{'column'},
      join "\n                                     ", @{$_->{'messages'}}
  }

  if( $puh->xml_error ) { ## only valid for HTML pages
    (my $t = $puh->xml_error ) =~ s{\s+\Z}{}mxs;
    $t =~ s{\n}{\n  }mxsg;
    printf {*STDERR} "\nXML error:\n%s\n", $t;
  }

  printf {*STDERR} "\n%s\n", $SPACER;

  return 1;
}

sub format_msg {
  my $string = shift;
  $string =~ s{\s+at\s+\S+\s+line\s+\d+.*\Z}{}mxs;
  $columns = $WRAP_COLUMNS;
  return fill( q(    ),q(    ), $string );
}

## Now the extension specific methods...

sub check_noextension {
#@param $params (hashref) of parameters
#@return (boolean) true if file is not commitable
## Checks files with no extension to see if they are commitable - this currently only allows perl files through!

  my $params = shift;
  my @contents = get_contents( $params );

  if( @contents ) {
    ## Look for magic-sigils - in this case a perl file!
    if( $contents[0] =~ m{\A\#!/usr/bin/perl}mxs ) {
      # We have a perl file so push it on the perl file list....
      $perl_files{ $params->{'filename'} } = join "\n", @contents;
      return 0;
    }
  }
  printf {*STDERR} "%s%s - DO NOT COMMIT EXTENSION LESS FILES\n%s\n",$SPACER,$params->{'filename'},$SPACER;
  return 1;
}

sub check_aspell {
  my $params = shift;
  return 0 if $params->{'filename'} =~ m{\A[^/]+/config/}mxs; ## Either in top level config
  printf {*STDERR} "aspell's prepl & pws directories files should be in the config directory\n", $params->{'filename'};
  return 1;
}

sub check_unknown {
#@param $params (hashref) of parameters
#@return (boolean) true as can't commit files of unknown extensions
## Returns true as currently can't check syntax of images...

#DEV - add code to check path is an "asset" path...
  my $params = shift;

  printf {*STDERR} "%s%s - DO NOT COMMIT UNKNOWN EXTENSION FILES (%s)\n%s\n",
    $SPACER,$params->{'filename'},$params->{'extension'},$SPACER;
  return 1;
}

sub check_conf {
#@param $params (hashref) of parameters
#@return (boolean) 0 if the file is in a an assets directory 1 otherwise
## Check syntax of PDF files

  my $params = shift;
  return 0 if $params->{'filename'} =~ m{/apache2/}mxs;
  printf {*STDERR} "Data file '%s' should be in a /apache2/ directory\n", $params->{'filename'};
  return 1;
}

sub check_data {
#@param $params (hashref) of parameters
#@return (boolean) 0 if the file is in a an assets directory 1 otherwise
## Check syntax of PDF files

  my $params = shift;
  return 0 if $params->{'filename'} =~ m{/data/}mxs || $params->{'filename'} =~ m{\A[^/]+/htdocs/robots.txt\Z}mxs;
  printf {*STDERR} "Data file '%s' should be in a /data/ directory\n", $params->{'filename'};
  return 1;
}

sub check_php {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of php files...
## Check syntax of PHP files

  my $params = shift;
  return 0 if $params->{'filename'} =~ m{/php/}mxs;
  printf {*STDERR} "PHP file '%s' should be in a /php/ directory\n", $params->{'filename'};
  return 1;
}

sub check_binaries {
#@param $params (hashref) of parameters
#@return (boolean) 0 if the file is in a an assets directory 1 otherwise

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'Binary files' );
  return 0 if $params->{'filename'} =~ m{/assets/}mxs;
  printf {*STDERR} "Binary file '%s' should be in a /assets/ directory\n", $params->{'filename'};
  return 1;
}

sub check_document {
#@param $params (hashref) of parameters
#@return (boolean) 0 if the file is in a an assets directory 1 otherwise
## Check syntax of PDF files
  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'Document' );
  return 0 if $params->{'filename'} =~ m{/assets/}mxs;
  printf {*STDERR} "Document file '%s' should be in a /assets/ directory\n", $params->{'filename'};
  return 1;
}

sub check_gif {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of images...
## Check syntax of image files

#DEV - add code to check images in "image path"....
  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'GIF' );

  unless( $params->{'filename'} =~ m{/core/gfx/blank.gif}mxs ||
          $params->{'filename'} =~ m{/core/gfx/anim/}mxs ||
          $params->{'filename'} =~ m{/__utm.gif\Z}mxs
  ) {
    printf {*STDERR} "Cannot commit gif files\n", $params->{'filename'};
    return 1;
  }

  my @contents = get_contents( $params );
  my $img = join qq(\n), get_contents( $params );

  my $p = Image::Magick->new( 'magick' => $params->{'extension'} );
  my $message = $p->BlobToImage( $img );
  if( $message ) {
    printf {*STDERR} "Image file '%s' has errors in it\n%s\n\n", $params->{'filename'}, format_msg( $message );
  }
  return 0;
}


sub check_html {
#@param $params (hashref) of parameters
#@return (boolean) true if not commitable
## Checks all HTML files - to see if they pass HTML tidy's critic, contain no "non-ascii characters OR tabs", and that they contain certain <meta> tags in head block

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'HTML' );

  my @contents = get_contents( $params );

  ## For templates add a doc type at the start..
  unshift @contents, qq(<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">) if $params->{'extension'} eq 'tmpl';

  my $html = join qq(\n), @contents;
  if( $params->{'extension'} eq 'tmpl' ) {
    ## Remove expanded out CSS/Javascript lines in templates.
    $html =~ s{(<link\s+rel="stylesheet"\s+type="text/css"\s+href=")([^"]+)("\s*/>)}{$1merged$3}mxsg; ## no critic (ComplexRegexes)
    $html =~ s{(<script\s+type="text/javascript"\s+src=")([^"]+)("\s*>)}{$1merged$3}mxsg;
  }
  ## Remove directives from within tags....
  1 while $html =~ s{(<[^<>]*)(<%.*?%>)}{$1.q( ) x length $2}msxe; ## Still may have an issue if tag is generated by <% %> which is probably bad anyway!

  ## Create a temporary copy so we can run critic on it!
  my $f = "/tmp/test.$PID.html";
  if( open my $FH, '>', $f ) {
    print {$FH} $html; ## no critic (RequireChecked)
    close $FH;       ## no critic (RequireChecked)
  } else {
    printf {*STDERR} "Unable to test tmp file for testing '%s'\n", $params->{'filename'};
    return 1;
  }
# Check the HTML passes critic!
  my $puh = Pagesmith::Utils::HTMLcritic->new( $f, 0 );
  my $flag = $puh->check;
  unlink $f;

# Check Head block
  if( $html =~ m{<head>(.*)</head>}mxs ) {
    my $head = $1;
    my $head_info = HTML::HeadParser->new();
    $head_info->parse($head);
    if( $params->{'extension'} eq 'tmpl' ) {
      unless( $head_info->header('X-Meta-Template-Svn-Id') ) {
        $puh->push_message( { 'level' => 'Error', 'line' => 0, 'column' => 0, 'messages' => [ 'No Template SVN-ID field' ] } );
      }
    } else {
      unless( $head_info->header('X-Meta-Svn-Id') ) {
        $puh->push_message( { 'level' => 'Error', 'line' => 0, 'column' => 0, 'messages' => [ 'No SVN-ID field' ] } );
      }
    }
    unless( $head_info->header('X-Meta-Author') ) {
      $puh->push_message( { 'level' => 'Error', 'line' => 0, 'column' => 0, 'messages' => [ 'No AUTHOR field' ] } );
    }
  }
# Check tabs/non-ascii
  _check_non_ascii( $puh, $html );
# Dump messages and return.!
  return dump_messages( $flag, $puh, $params->{'filename'} );
}

sub _check_lower {
  my( $name, $type ) = @_;
  return unless $name =~ m{\A[^/]+/htdocs(-\w+)?/}mxs; ## Only check htdocs directories...
  return unless $name =~ m{[[:upper:]]}mxs;                  ## Return if it doesn't contain any Uppercase letters
  printf {*STDERR} "Cannot commit %s files with upper case characters in names '%s'\n", $type, $name;
  return 1;
}

sub check_html_inc {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of inc files
## Check syntax of (HTML) include files

#DEV - will eventually run through HTML tidy fragment to check valid!

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'INC' );
  return 0 if $params->{'filename'} =~ m{/inc/}mxs;
  printf {*STDERR} "Include file '%s' should be in a /inc/ directory\n", $params->{'filename'};
  return 1;
}

sub check_image {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of images...
## Check syntax of image files

#DEV - add code to check images in "image path"....
  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'Image' );
  unless( $params->{'filename'} =~ m{/(gfx|icons|i)/}mxs ) {
    printf {*STDERR} "Image file '%s' should be in a /gfx/ directory\n", $params->{'filename'};
    return 1;
  }

  my @contents = get_contents( $params );
  my $img = join qq(\n), get_contents( $params );

  my $p = Image::Magick->new( 'magick' => $params->{'extension'} );
  my $message = $p->BlobToImage( $img );
  if( $message ) {
    printf {*STDERR} "Image file '%s' has errors in it\n%s\n\n", $params->{'filename'}, format_msg( $message );
  }
  return 0;
}

sub check_java {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of pdf files...
## Check syntax of PDF files

  my $params = shift;
  unless( $params->{'filename'} =~ m{/java/}mxs ) {
    printf {*STDERR} "JAVA file '%s' should be in a /java/ directory\n", $params->{'filename'};
    return 1;
  }
#DEV - add XML checker on jnlp files...
  return _check_xml( $params ) if $params->{'extension'} eq 'jnlp';
  return 0;
}

sub check_javascript {
#@param $params (hashref) of parameters
#@return (boolean) true if not commitable
## Checks all Javascript files - to see if they pass JSL's tests, contain no "non-ascii characters OR tabs"

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'Javascript' );
  unless( $params->{'filename'} =~ m{/js/}mxs ) {
    printf {*STDERR} "Javascript file '%s' should be in a /js/ directory\n", $params->{'filename'};
    return 1;
  }

  my $javascript = join qq(\n), get_contents( $params );
  ## Create a temporary copy so we can run critic on it!
  my $f = "/tmp/test.$PID.js";
  if( open my $FH, '>', $f ) {
    print {$FH} $javascript; ## no critic (RequireChecked)
    close $FH;               ## no critic (RequireChecked)
  } else {
    printf {*STDERR} "Unable to create tmp file for testing '%s'\n", $params->{'filename'};
    return 1;
  }
# Check the HTML passes critic!
  my $puh = Pagesmith::Utils::JScritic->new( $f );
  my $flag = $puh->check;
  unlink $f;

  _check_non_ascii( $puh, $javascript );
  return dump_messages( $flag, $puh, $params->{'filename'} );
}

sub check_json {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of pdf files...
## Check syntax of PDF files

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'JSON' );

  unless( $params->{'filename'} =~ m{/(js|config|data)/}mxs ) { ## Should be in a js, data or config directory
    printf {*STDERR} "Javascript file '%s' should be in a /js/ directory\n", $params->{'filename'};
    return 1;
  }

  my $json   = join qq(\n), get_contents( $params );
  my $ret    = eval {
    decode_json $json;
  };
  return 0 unless $EVAL_ERROR;
  printf {*STDERR} "Syntax error in config (json) file '%s'\n%s\n\n", $params->{'filename'}, format_msg( $EVAL_ERROR );
  return 1;
}

sub check_ms_xml {
#@param $params (hashref) of parameters
#@return (boolean) true as can't commit M$ XML files
## Forbids the submission of M$ Office 2007 - docx/pptx/xlsx files

  my $params = shift;
  printf {*STDERR} "%s%s - DO NOT COMMIT M\$ XML formats - use older more compatible format!\n%s\n",$SPACER,$params->{'filename'},$SPACER;
  return 1;
}

sub check_pdf {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of pdf files...
## Check syntax of PDF files

  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'PDF' );
  return 0 if $params->{'filename'} =~ m{/assets/}mxs;
  printf {*STDERR} "PDF file '%s' should be in a /assets/ directory\n", $params->{'filename'};
  return 1;
}

sub check_perl {
#@param $params (hashref) of parameters
#@return (boolean) false - we postpone checking of perl files to a later stage!
## Stores the contents of the file for later syntax checking

  my $params = shift;
  my @contents = get_contents( $params );
  $perl_files{ $params->{'filename'} } = join "\n", @contents;
  return 0;
}

sub check_stanza {
#@param $params (hashref) of parameters
#@return (boolean) false - we postpone checking of perl files to a later stage!
## Stores the contents of the file for later syntax checking

  my $params = shift;

  my $ini_contents = join qq(\n), get_contents( $params );
  ## Create a temporary copy so we can run critic on it!
  my $f = "/tmp/test.$PID.ini";
  if( open my $FH, '>', $f ) {
    print {$FH} $ini_contents; ## no critic (RequireChecked)
    close $FH;               ## no critic (RequireChecked)
  } else {
    printf {*STDERR} "Unable to create tmp file for testing '%s'\n", $params->{'filename'};
    return 1;
  }
  my $cfg = Config::IniFiles->new( '-file' => $f );
  return 0 if defined $cfg;
  printf {*STDERR} "Syntax error in config file '%s'\n\n", $params->{'filename'};
  return 1;
}

sub check_stylesheet {
#@param $params (hashref) of parameters
#@return (boolean) 0 - file is OK if within a /css/ directory or 1 otherwise
## Check syntax of CSS files

#DEV - add code to check css files in "css" directory....
  my $params = shift;
  return 1 if _check_lower( $params->{'filename'}, 'CSS' );
  return 0 if $params->{'filename'} =~ m{/css|i/}mxs;
  printf {*STDERR} "CSS file '%s' should be in a /css/ directory\n", $params->{'filename'};
  return 1;
}

sub _check_xml {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of xml files...
## Check syntax of XML files
  my $params = shift;
  ## use XML parser to check the syntax of XML files!
  my $xml = join qq(\n), get_contents( $params );
  my $parser = XML::Parser->new( 'ErrorContext' => 2 );
  my $ret_val = eval {
    $parser->parse( $xml );
  };
  return 0 unless $EVAL_ERROR;
  printf {*STDERR} "Syntax error in XML file '%s'\n%s\n\n", $params->{'filename'}, format_msg( $EVAL_ERROR );
  return 1;
}

sub check_xml {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of xml files...
## Check syntax of XML files
  my $params = shift;
  ## Pass it into the check_xml call (separated out so it can be used on different xml files)
  return 1 if _check_lower( $params->{'filename'}, 'XML' );
  return _check_xml( $params );
}

sub check_sql {
  my $params = shift;
  return 0 if $params->{'filename'} =~ m{\A[^/]+/(data/)?config/}mxs; ## Either in top level config OR site/data/config...
  printf {*STDERR} "ORA, SQLLIB & SQL files '%s' should be in a /config/ directory\n", $params->{'filename'};
  return 1;
}

sub check_ico {
   my $params = shift;
   return 0 if $params->{'filename'} =~ m{\A[^/]+/htdocs(-\w+)?/favicon.ico}mxs;
   printf {*STDERR} "Favicon is the only ico file allowed\n", $params->{'filename'};
   return 1;
}

sub check_source {
  my $params = shift;
  return 0 if $params->{'filename'} =~ m{\A[^/]+\w+/source/}mxs;
  printf {*STDERR} "Source etc files '%s' should be in the /source/ directory\n", $params->{'filename'};
  return 1;
}

sub check_yaml {
#@param $params (hashref) of parameters
#@return (boolean) false as can't check syntax of pdf files...
## Check syntax of PDF files

  my $params = shift;
  my $yaml   = join qq(\n), get_contents( $params );
  my $loader = YAML::Loader->new;
  my $structure;
  my $ret_val = eval {
    $structure = $loader->load( $yaml );
  };
  return 0 unless $EVAL_ERROR;
  printf {*STDERR} "Syntax error in config (yaml) file '%s'\n%s\n\n", $params->{'filename'}, format_msg( $EVAL_ERROR );
  return 1;
}
