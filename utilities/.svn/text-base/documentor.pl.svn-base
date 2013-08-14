#!/usr/bin/perl

## Retrieve documentation for all perl files...

## Author         : js5
## Maintainer     : js5
## Created        : 2012-11-19
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Perl::Critic;
use Data::Dumper    qw(Dumper);
use Getopt::Long    qw(GetOptions);
use Time::HiRes     qw(time);
use English         qw(-no_match_vars $INPUT_RECORD_SEPARATOR $PROGRAM_NAME $EVAL_ERROR);
use Date::Format    qw(time2str);
use File::Path      qw(mkpath);
use File::Basename  qw(dirname);
use Cwd             qw(abs_path);
use HTML::Entities  qw(encode_entities);
use IO::File;
use List::MoreUtils qw(any);

use Const::Fast qw(const);
const my $MAX_LENGTH => 50;
my $ROOT_PATH;
BEGIN {
  $ROOT_PATH = dirname(dirname(abs_path($PROGRAM_NAME)));
}

use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::Documentor::Package;
use Pagesmith::Utils::Documentor::File;
use Pagesmith::HTML::Tabs;
use Pagesmith::HTML::TwoCol;
use Pagesmith::HTML::Table;

my $site      = 'apps.sanger.ac.uk';
my $html_path = 'docs/perl';

GetOptions(
  'site=s'  => \$site,
  'path=s'  => \$html_path,
);

my $t_init = time;
my $res = find_perl_dirs();
my $files = {};
my $t = time;
my $cc = 0;
my $parsed_files = {};
my $module_cache = {};
my $root_docs = $ROOT_PATH.'/sites/'.$site.'/htdocs/'.$html_path.q(/);

STDERR->autoflush(1); ## no critic (ExplicitInclusion)

mkpath( "$root_docs/inc/methods" );
mkpath( "$root_docs/inc/method_links" );
mkpath( "$root_docs/js" );
mkpath( "$root_docs/css" );

write_file( 'index.html',         generate_index_file(), 1 );
write_file( 'js/documentor.js',   generate_js_file(),    1 );
write_file( 'css/documentor.css', generate_css_file(),   1 );
dump_timer( 'Generated index file' );


foreach my $libpath (@{$res->{'paths'}}) {
  get_perl_files( $files, $libpath, q(), $libpath );
}
#print raw_dumper( $files );exit;
dump_timer( 'Got file list' );

foreach my $path ( sort keys %{$files} ) {
  my $c=0;
  ( my $root_file_name   = $res->{'map'}{$path} ) =~ s{/}{_}mxsg;
  foreach my $module ( sort keys %{$files->{$path}} ) {
    my $filename = $files->{$path}{$module};
    my $package_obj = get_details_file( $filename, $module );
       $package_obj->set_root_directory( $path );
    ( my $output_file_name = $package_obj->name )                          =~ s{::}{-}mxsg;
    $package_obj->set_doc_filename( sprintf '%s-%s.html', $root_file_name, $output_file_name );
    $parsed_files->{$filename} = $package_obj;
    $module_cache->{$package_obj->name} = $package_obj;
    $c++;
  }
  dump_timer( q(  ).$res->{'map'}{$path}, $c );
  $cc+=$c;
}
dump_timer( 'Parsed', $cc );

my ( $used_by_packages, $method_details, $descendants, @packages ) = invert_lists();
write_file( 'inc/used.inc', raw_dumper( $used_by_packages ) );

dump_timer( 'Generated inverted index' );

my @method_details = generate_method_lists();

dump_timer( 'Generated method lists' );

## Write front page module list file...
write_file( 'inc/module_list.inc', module_table( \@packages )->render );
dump_timer( 'Generated module page' );
## Write front page method list file...
write_file( 'inc/method_list.inc', method_table( @method_details )->render );
dump_timer( 'Generated method page' );
## Generate the menu HTML and all the HTML pages...
write_file( 'inc/list.inc', join qq(\n), generate_tree(), q(), sprintf
  '<dl class="twocol twothird"><dt>Time taken:</dt><dd>%0.3f seconds</dd><dt>Run at:</dt><dd>%s</dd><dt>Run on:</dt><dd>%s</dd></dl>',
  time-$t_init, time2str( '%H:%M %Z', time ),
  time2str( '%A, %d %B %Y', time ),
);

dump_timer( 'Written' );
exit;

sub dump_timer {
  my( $msg, $count ) = @_;
  my $t_last = time;
  if( defined $count ) {
    printf {*STDERR} "%-40s : %5d %7.3f %7.3f\n", $msg, $count, $t_last - $t, $t_last - $t_init;
  } else {
    printf {*STDERR} "%-40s :       %7.3f %7.3f\n", $msg, $t_last - $t, $t_last - $t_init;
  }
  $t = $t_last;
  return;
}

sub write_file {
  my( $fn, $contents, $create_only ) = @_;
  ## no critic (RequireChecked)
  $fn = "$root_docs/$fn" unless $fn =~ m{\A/}mxs;
  return 1 if $create_only && -e $fn;
  if( open my $fh, q(>), $fn ) {
    print {$fh} $contents;
    close $fh;
    return 1;
  }
  ## use critic
  return;
}

sub generate_tree {
  my @tree = (q(<ul id="navigation"><li class="node"><a href="index.html">Module/Method lists</a></li>));
  foreach my $path ( sort keys %{$files} ) {
    my $c=0;
    push @tree, sprintf q(<li class="branch coll"><span style="font-weight:bold">%s</span><ul>), $res->{'map'}{$path};
    my @current_branch;
    foreach my $module ( sort keys %{$files->{$path}} ) {
      my $filename = $files->{$path}{$module};
      my $package_obj = $parsed_files->{$filename};
      write_docs_file( $root_docs.$package_obj->doc_filename, $package_obj );
      my @this_branch = split m{::}mxs, $module;
      if( $this_branch[0] eq 'Pagesmith' ) {
        shift @this_branch;
        unshift @this_branch, 'Pagesmith::'.shift @this_branch;
      }
      my @temp_branch = @this_branch;
      my $previous_node = pop @current_branch;
      my $node          = pop @temp_branch;
      while( @temp_branch && @current_branch ) {
        last if $current_branch[0] ne $temp_branch[0];
        shift @current_branch;
        shift @temp_branch;
      }
      foreach( @current_branch ) {
        push @tree, q(</ul></li>);
      }
      foreach( @temp_branch ) {
        push @tree, qq(<li class="branch coll"><span>$_</span><ul>);
      }
      push @tree, sprintf q(<li class="node"><a href="%s">%s</a></li>), $package_obj->doc_filename,$node;
      @current_branch = @this_branch;
      ## Now we have to push the entry into the tree!
      $c++;
    }
    foreach ( @current_branch ) {
      push @tree, q(</ul></li>);
    }
    dump_timer( q(  ).$res->{'map'}{$path}, $c );
  }
  push @tree, q(</ul>);
  return @tree;
}

sub generate_method_lists {
  my @details;
  foreach my $method_name ( sort keys %{$method_details} ) {
     my $row = {
      'name' => $method_name,
      'modules'     => [
        map   { $module_cache->{$_} }
        grep  { $method_details->{$method_name}{$_} == 2 }
        sort keys %{ $method_details->{$method_name}},
      ],
      'full_modules' => [
        map   { $module_cache->{$_} }
        sort keys %{$method_details->{$method_name}},
      ],
    };
    push @details, $row;
    write_file( "inc/method_links/$method_name.inc", method_dump( $row ) );
  }
  return @details;
}

sub invert_lists {
  my @pack;
  my $meth_det;
  my $desc_list;
  my $used_by;
  foreach my $path ( sort keys %{$files} ) {
    foreach my $module ( sort keys %{$files->{$path}} ) {
      my $filename    = $files->{$path}{$module};
      my $package_obj = $parsed_files->{$filename};
      my @list_of_packages;
      my $pname = $package_obj->name;
      isa_list( $package_obj, \@list_of_packages ) if $package_obj->parents;
      $package_obj->set_ancestors( @list_of_packages );
      $desc_list->{$_}{$pname} = 1 foreach @list_of_packages;
      my %used = $package_obj->used_packages;
      $used_by->{$_}{$pname}   = 1 foreach sort keys %used;
      $desc_list->{$_}{$pname} = 2 foreach $package_obj->parents;
      push @pack, $package_obj;
      my @methods = $package_obj->methods;
      my %seen_methods = map { ( $_->name => 1 ) } @methods;
      $meth_det->{ $_->name }{ $pname } = 2 foreach @methods;
      my $hidden = {};
      foreach my $par ( $package_obj->ancestors ) {
        next unless exists $module_cache->{$par};
        foreach my $method_obj ( $module_cache->{$par}->methods ) {
          $meth_det->{ $method_obj->name }{$pname}||=1;
          if( $seen_methods{ $method_obj->name } ) {
            $hidden->{$par}{$method_obj->name}=1;
          } else {
            $seen_methods{ $method_obj->name }=1;
          }
          push @methods, $method_obj;
        }
      }
      $package_obj->set_full_methods( \@methods, $hidden );
    }
  }
  return ( $used_by, $meth_det, $desc_list, @pack );
}

sub method_dump {
  my $details = shift;
  my $n_mods = scalar @{$details->{'modules'}};
  my $n_all  = scalar @{$details->{'full_modules'}};
  ## no critic (LongChainsOfMethodCalls)
  my $t_mods = Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( [qw(10 20 50 100 all)], '20' )
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name', 'label' => 'Package', 'link' => '[[h:doc_filename]]' },
      { 'key' => 'root_directory',     'label' => 'Root dir',  'code_ref' => sub { return $res->{'map'}{$_[0]->root_directory}; } },
      { 'key' => 'location',                    'label' => 'Location', 'code_ref' => sub {
        my ($method_obj) = grep { $_->name eq $details->{'name'} } $_[0]->methods;
        return sprintf '<a href="%s#line_%d">%d-%d</a>', $_[0]->doc_filename, $method_obj->start, $method_obj->start, $method_obj->end;
        }, 'format' => 'r',
      },
    )
    ->add_data( @{$details->{'modules'}} );

  my $t_all = Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( [qw(10 20 50 100 all)], '20' )
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name', 'label' => 'Package', 'link' => '[[h:doc_filename]]' },
      { 'key' => 'root_directory',     'label' => 'Root dir',  'code_ref' => sub { return $res->{'map'}{$_[0]->root_directory}; } },
      { 'key' => 'location',                    'label' => 'Location', 'code_ref' => sub {
        my ($method_obj) = grep { $_->name eq $details->{'name'} } $_[0]->methods;
        return sprintf '<a href="%s#line_%d">%d-%d</a>', $_[0]->doc_filename, $method_obj->start, $method_obj->start, $method_obj->end;
        }, 'format' => 'r',
      },
    )
    ->add_data( @{$details->{'full_modules'}} );
  ## use critic
  ## no critic (ImplicitNewlines)
  return sprintf '<h3>Method: %s</h3>
  <ul class="tabs">
    <li><a href="#method_package_list">Modules (%d)</a></li>
    <li><a href="#method_package_all">All Modules (%d)</a></li>
  </ul>
  <div id="method_package_list"><h3>Modules</h3>
    %s
  </div>
  <div id="method_package_all"><h3>All Modules</h3>
    %s
  </div>
  ', $details->{'name'}, $n_mods, $n_all, $t_mods->render, $t_all->render;
  ## use critic
}

sub module_table {
  my $packages = shift;
  return Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( [qw(10 20 50 100 all)], '20' )
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name',               'label' => 'Name',
        'link' => '[[h:doc_filename]]' },
      { 'key' => 'root_directory',     'label' => 'Root dir',  'code_ref' => sub { return $res->{'map'}{$_[0]->root_directory}; } },
      { 'key' => 'methods',            'label' => '# Methods', 'format'=>'f', 'code_ref' => sub { return scalar ( $_[0]->methods ) } },
      { 'key' => 'all_methods',        'label' => '# All',     'format'=>'f', 'code_ref' => sub { return scalar ( $_[0]->full_methods ) } },
    )
    ->add_data( @{$packages} );
}

sub method_table {
  my @meth_details = @_;
  return Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( [qw(10 20 50 100 all)], '10' )
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name',             'label' => 'Name', 'link' => 'class=method_list #[[h:name]]' },
      { 'key' => 'packages',         'label' => '# Packages', 'format'=>'f', 'code_ref' => sub { return scalar @{$_[0]{'modules'}} }},
      { 'key' => 'all_packages',     'label' => '# All',      'format'=>'f', 'code_ref' => sub { return scalar @{$_[0]{'full_modules'}} }},
    )
    ->add_data( @meth_details );
}
sub find_perl_dirs {
#@params
#@return (hashref paths)
## hashref contains two elements an arrayref of paths and a hashref mapping these paths to a more human friendly form
## * looks for a top level lib and utilities directory and then in every top level directory and directory in sites for lib/utilities/cgi/perl sub directories
  my $dir_root = $ROOT_PATH;
  my @lib_paths;
  my %dir_map;
  foreach ( qw(lib utilities) ) {
    push @lib_paths, "$dir_root/$_";
    $dir_map{"$dir_root/$_"} = $_;
  }
  my $dh;
  my @dirs;
  if( opendir $dh, "$dir_root/sites" ) {
    while ( defined (my $file = readdir $dh) ) {
      next if $file =~ m{\A[.]}mxs;
      push @dirs, [ "$dir_root/sites/$file", $file ];
    }
    closedir $dh;
  }
  if( opendir $dh, $dir_root ) {
    while ( defined (my $file = readdir $dh) ) {
      next if $file =~ m{\A[.]}mxs;
      push @dirs, [ "$dir_root/$file", $file ];
    }
    closedir $dh;
  }
  foreach my $a_ref ( sort { $a->[0] cmp $b->[0] } @dirs) {
    my $new_path = $a_ref->[0];
    my $file     = $a_ref->[1];
    foreach ( qw(lib utilities cgi perl) ) {
      if( -d $new_path && -d "$new_path/$_" ) {
        $dir_map{ "$new_path/$_" } = "$file/$_";
        push @lib_paths, "$new_path/$_";
      }
    }
  }
  return {(
    'paths' => \@lib_paths,
    'map'   => \%dir_map,
  )};
}

sub get_perl_files {
#@params (hashref{} files) (string current directory) (string prefix) (string root)
#@return
## Gets a list of all perl files in "root" directory
## * files hash is a hashref of hashrefs keyed by root directory & "package name" i.e. path separated by "::"
## * looks for all .pm/.pl files as well as files whose first lines starts #!/....perl
  my( $l_files, $path, $prefix, $root ) = @_;
  return unless -e $path && -d $path && -r $path;
  my $dh;
  return unless opendir $dh, $path;
  while ( defined (my $file = readdir $dh) ) {
    my $new_path = "$path/$file";
    next if $file =~ m{^[.]}mxs;
    next if $file =~ m{([.]b[ac]k|~)$}mxs;
    if( -f $new_path ) { ## no critic (Filetest_f)
      if( $file =~ m{^(.*)[.]p[ml]$}mxs ) { ## .pl || .pm files
        $l_files->{$root}{ "$prefix$1" } = $new_path;
      } else { ## Check other files to see if have #! line...
        next unless open my $in_fh, '<', $new_path;
        my $first_line = <$in_fh>;
        close $in_fh; ## no critic (RequireChecked)
        $l_files->{$root}{ "$prefix$file" } = $new_path if $first_line && $first_line =~ m{^\#!.*perl}mxs;
      }
    } elsif( -d $new_path ) {
      get_perl_files( $l_files, $new_path, "$prefix$file".q(::), $root );
    }
  }
  return;
}

## no critic (ExcessComplexity)
sub get_details_file {
#@params (string file name) (string module name)
#@return (Pagesmith::Utils::Documentor::Package) package object
## Opens and parses the perl file
## * Very complex (and in someways naive) method which opens the perl file as plain text, and looks line
##   by line through the file for rcs keywords, other modules used, package variables & constants, and
##   also for methods and their signatures
  my( $filename, $module_name ) = @_;
  my $file_object = Pagesmith::Utils::Documentor::File->new( $filename );
  my $package     = Pagesmith::Utils::Documentor::Package->new( $file_object );
  $package->set_name( $module_name );
  $file_object->open_file;

  my $start_block = 1;
  my $current_sub;
  my $flag;
  my $raw_flag = 0;
  while( my $line = $file_object->next_line ) {
    ## no critic (CascadingIfElse ComplexRegexes)
    if( $line =~ m{\A[#]!}mxs ) {
      next;
    }
    if( $start_block ) {
      if( $line =~ m{package\s+([\w:]+)}mxs ) {
        $package->set_name( $1 );
      } elsif( $line =~ m{[#]{2}\s*(Author|Maintainer|Created|Last[ ]commit[ ]by|Last[ ]modified|Revision|Repository[ ]URL)\s*:\s*(.*)}mxs ) {
        $package->set_rcs_keyword( $1, $2 );
      } elsif( $line =~ m{[#]{2}\s*(.*)}mxs ) {
        $package->push_description( $1 );
      } elsif( $line =~ m{\S}mxs) {
        $start_block = 0;
      }
    }
    if( $line =~ m{\A[#][@]raw}mxs ) {
      $file_object->empty_line;
      $raw_flag = 1;
      next;
    }
    if( $line =~ m{\A[#][@]endraw}mxs ) {
      $file_object->empty_line;
      $raw_flag = 0;
      next;
    }
    ## use critic
    next if $raw_flag;

    if( $line =~ m{\A__(?:END|DATA)__}mxs ) {
      ## We now are at the end of the file - grab extra markup!
      $file_object->empty_line;
      while( my $end_line = $file_object->next_line ) {
        $package->push_notes( $end_line );
        $file_object->empty_line;
      }
      last;
    }
    if($line =~ m{\Asub\s+(\S+)}mxs ) {
      ## Start of sub
      $current_sub  = $package->new_method( $1 );
      $current_sub->set_start( $file_object->line_count );
      $current_sub->set_end(   $file_object->line_count );
      $start_block  = 0;
      $flag         = 1;
      next;
    }
    if($line =~ m/\A}/mxs) {
     ## End of sub
      next unless $current_sub;
      $current_sub->set_end( $file_object->line_count );
      $current_sub = undef;
      next;
    }
    unless( $current_sub ) {
      # Use base...
      if( $line =~ m{\A\s*use\s+base\s+q[qw]?[(]\s*(.*?)\s*[)]}mxs ||
        $line =~ m{\A\s*use\s+base\s+["']\s*(.*?)\s*["']}mxs ) {
        $package->set_parents( split m{\s+}mxs, $1 );
        next;
      }
      # Now we do the other use lines... - use
      if( $line =~ m{\A\s*use\s+([\w:]+)\s*;}mxs ) {
        $package->push_use( $1 );
        next;
      }
      # use with with import!
      if( $line =~ m{\A\s*use\s+([\w:]+)\s+q[qw]?[(]\s*(.*?)\s*[)]}mxs ||
        $line =~ m{\A\s*use\s+([\w:]+)\s+["']\s*(.*?)\s*["']}mxs ) {
        $package->push_use( $1, split m{\s+}mxs, $2);
        next;
      }
      ## no critic (ComplexRegexes)
      if( $line =~ m{\A\s*(?:Readonly|Const::Fast)\s+my\s+([\$]\w+)\s*=>\s*(.*?);?\Z}mxs ) {
        $package->push_constant( $1, $2 );
        next;
      }
      if( $line =~ m{\A\s*my\s+([\$]\w+)\s*=\s*(.*?);?\Z}mxs ) {
        $package->push_package_variable( $1, $2 );
        next;
      }
      if( $line =~ m{\A\s*my\s+([\$]\w+);\Z}mxs ) {
        $package->push_package_variable( $1 );
      }
      next;
      ## use critic
    }
    if( $line =~ m{\A[#][@]class\s*(\S+)}mxs ) {
      $current_sub->set_class( $1 );
      $file_object->empty_line;
      next;
    }
    # Format of #@params line is (TYPE NAME? - DESC?)OPT? {repeated foreach parameter
    #  - TYPE is a non-white space string { can be postfixed with [] or {} to indicate an arrayref/hashref
    #  - NAME is a string (optional)
    #  - DESC is a string - not containing a ')' (optional)
    #  - OPT  is a flag (*+?) to represent 0+, 1+ or 0/1 respectively
    if( $line =~ m{\A[#][@]params\s*(.*)}mxs ) {
      $current_sub->set_documented;
      my $params = $1;
      while( $params =~ s{\A[(](\S+?)(?:\s+(.*?)\s*)?[)]([*+?]?)(\s.*|)\Z}{$4}mxs ) {
        my( $description, $type, $optional, $name ) = (q(),$1,$3,$2);
        if( $name && $name =~ s{\s+-\s+(.*)\Z}{}mxs ) {
          $description = $1;
        }
        $current_sub->push_parameter( $type, $name, $optional, $description );
        $params =~ s{\A\s+}{}mxs;
      }
      $file_object->empty_line;
      next;
    }
    # Format of #@param line is (TYPE)OPT? NAME? - DESC?
    #  - TYPE is a non-white space string { can be postfixed with [] or {} to indicate an arrayref/hashref
    #  - NAME is a string (optional)
    #  - DESC is a string (optional)
    #  - OPT  is a flag (*+?) to represent 0+, 1+ or 0/1 respectively
    if( $line =~ m{\A[#][@]param\s*[(](\S+?)[)]([*+?]?)(?:\s+(.*))?\Z}mxs ) {
      my( $description, $type, $optional, $name ) = (q(),$1,$2,$3);
      if( $name && $name =~ s{\s+-\s+(.*)\Z}{}mxs ) {
        $description = $1;
      }
      $current_sub->set_documented;
      $current_sub->push_parameter( $type, $name, $optional, $description );
      $file_object->empty_line;
      next;
    }

    # Format of #@returns line is (TYPE DESC?)OPT? {repeated foreach parameter
    #  - TYPE is a non-white space string { can be postfixed with [] or {} to indicate an arrayref/hashref
    #  - DESC is a string - not containing a '(' (optional) - and cannot be set if name isn't set
    #  - OPT  is a flag (*+?) to represent 0+, 1+ or 0/1 respectively
    if( $line =~ m{\A[#][@]returns\s*(.*)}mxs ) {
      $current_sub->set_documented;
      my $params = $1;
      while( $params =~ s{\A[(](\S+?)(?:\s+(.*?)\s*)?[)]([*+?]?)(\s.*|)\Z}{$4}mxs ) {
        my( $type, $optional, $description ) = (q(),$1,$3,$2);
        $current_sub->push_return( $type, $optional, $description );
        $params =~ s{\A\s+}{}mxs;
      }
      $file_object->empty_line;
      next;
    }
    # Format of #@return line is (TYPE)OPT? DESC 
    #  - TYPE is a non-white space string { can be postfixed with [] or {} to indicate an arrayref/hashref
    #  - DESC is a string (optional)
    #  - OPT  is a flag (*+?) to represent 0+, 1+ or 0/1 respectively
    if( $line =~ m{\A[#][@]return\s*[(](\S+?)[)]([*+?]?)(?:\s+(.*))?\Z}mxs ) {
      my( $type, $optional, $description ) = ($1,$2,$3);
      $current_sub->set_documented;
      $current_sub->push_return( $type, $optional, $description );
      $file_object->empty_line;
      next;
    }
    if( $line =~ m{\A[#][@]return\s*\Z}mxs ) {
      $current_sub->set_documented;
      $current_sub->push_return( '-none-', q(), '-none-' );
      $file_object->empty_line;
      next;
    }
    if( $line =~ m{\A[#]{2}\s?(.*)}mxs && $flag ) {
      $current_sub->set_documented;
      my $note = $1||qq(\n);
      if( $note !~ m{\A\w}mxs ) {
        $flag = 2;
      }
      if( $flag == 1 ) {
        $current_sub->push_description( $note );
      } else {
        $current_sub->push_notes( $note );
      }
      $file_object->empty_line;
      next;
    }
    $flag = 0;

    ## Now we don't have any parameters so look for the first "my" line!
    next if $current_sub->number_parameters;
    if( $line =~ m{\A\s*my\s*[(]\s*(.*?)\s*[)]\s*=\s*[@]_}mxs ) {
      my @params = split m{\s*,\s*}mxs, $1;
      foreach ( @params ) {
        if( m{([\$%@])(\w+)}mxs ) {
          $current_sub->push_parameter( $2 eq 'self'|| $2 eq 'class' ? $2 : q(), $1 eq q($) ? q() : q(*), $2 );
        } else {
          $current_sub->push_parameter( $_, q(), q() );
        }
      }
      next;
    }
    if( $line =~ m{\A\s*my\s+[\$](\w+)\s*=\s*shift}mxs ) {
      $current_sub->push_parameter( $1 eq 'self'|| $1 eq 'class' ? $1 : q(), q(), $1 );
      next;
    }
    if( $line =~ m{\A\s*return\s+shift->}mxs ) {
      $current_sub->push_parameter( 'self', q(), q(self) );
    }
  }
  $file_object->close_file;
  return $package;
}
## use critic

sub isa_list {
#@params (Pagesmith::Utils::Documentor::Package package object) (string[] ISA list)
#@return
## Updates the arrayref passed in as the second parameter with the full parent tree of the object
## * returns in the order the tree is searched for methods if there is multiple inheritance
## * used in two places - once to generate the full parent list on details page and also to get the list of methods in the "all methods" tab
  my ( $package_obj, $isa_list ) = @_;
  if( $package_obj->parents ) {
    foreach my $pg ( $package_obj->parents ) {
      next if any { $pg eq $_ } @{$isa_list};
      push @{$isa_list}, $pg;
      next unless exists $module_cache->{$pg};
      isa_list( $module_cache->{$pg}, $isa_list );
    }
  }
  return;
}

sub raw_dumper {
#@params (hashref|arrayref object to dump) (string name of object)?
#@return (string) compact sorted Data::Dumper output
  my( $data_to_dump, $name_of_data ) = @_;
  return Data::Dumper->new( [ $data_to_dump ], [ $name_of_data ] )->Sortkeys(1)->Indent(1)->Terse(1)->Dump();
}

sub write_docs_file {
#@params (string filename - location for documentation file) (Pagesmith::Utils::Documentor::Package package object)
#@return
## Generate documentation file for package with information stored in package_obj...
  my( $filename, $package_obj ) = @_;
  my $tabs = Pagesmith::HTML::Tabs->new;
  $tabs->add_tab( 'details', 'Details',            generate_details( $package_obj ) );
  $tabs->add_tab( 'child_tab', 'Children',         generate_children( $package_obj ) )
    if exists $descendants->{$package_obj->name};
  $tabs->add_tab( 'used_by',   'Used by',          generate_used( $package_obj ) )
    if exists $used_by_packages->{$package_obj->name};
  $tabs->add_tab( 'summary', 'Methods',            generate_summary( $package_obj ) );
  if( $package_obj->parents ) {
    my $html = generate_summary_full( $package_obj );
    if( $html ) {
      ( my $fn = $package_obj->doc_filename ) =~ s{[.]html\Z}{.inc}msx;
      ( my $output_filename = $filename     ) =~ s{[^/]+\Z}{inc/methods/$fn}mxs;
      $tabs->add_tab( 'summary_full', 'All methods', sprintf '<%% File -ajax /docs/perl/inc/methods/%s %%>', $fn );
      write_file( $output_filename, $html );
    }
  }
  $tabs->add_tab( 'docs',    'Documented methods', generate_methods( $package_obj ) );
  $tabs->add_tab( 'general', 'General notes',      generate_notes(   $package_obj ) );
  $tabs->add_tab( 'source',  'Source',             generate_source(  $package_obj ) );
  if( $package_obj->name =~ m{\APagesmith::Component::(.*)\Z}mxs ) {
    $tabs->add_tab( 'Usage',  'Usage',             sprintf '<%% Usage %s %%>', $1 );
  }
  ## no critic (ImplicitNewlines)
  my $markup = sprintf q(<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <title>Package: %s</title>
  <%% CssFile /docs/perl/css/documentor.css /core/css/beta/nav.css %%>
  <%% JsFile  /docs/perl/js/documentor.js   /core/js/beta/nav.js   %%>
</head>
<body id="documentor">
  <div id="main">
    <div class="panel">
      <h2><span class="toggle-width"><=></span>%s</h2>
      %s
    </div>
  </div>
  <div id="rhs">
    <div class="panel"><h3>Files</h3>
    <%% File inc/list.inc %%>
    </div>
  </div>
</body>
</html>
),
    $package_obj->name,
    $package_obj->name,
    $tabs->render;
  ## use critic
  write_file( $filename, $markup );
  return;
}

sub generate_source {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate component placeholder for full source code for file
## * Note can't use -ajax in this case as we want to allow deep-linking into the source code
  my $package_obj = shift;
  my $short_filename = substr $package_obj->file->name, length $ROOT_PATH;
  return sprintf '<%% Markedup -format perl -number line %s %%>',
    $short_filename;
}

sub generate_used {
  my $package_obj = shift;
  my $c = Pagesmith::HTML::TwoCol->new;
  my $my_modules = $used_by_packages->{$package_obj->name};
  foreach ( sort keys %{$my_modules} ) {
    my $name = $_;
    $name = sprintf '<a href="%s">%s</a>', $module_cache->{$_}->doc_filename, $name
      if exists $module_cache->{$_};
    $c->add_entry( 'Used by', $name );
  }
  return $c->render;
}

sub generate_children {
  my $package_obj = shift;
  my $c = Pagesmith::HTML::TwoCol->new;
  my $d = Pagesmith::HTML::TwoCol->new;
  my $my_descendants = $descendants->{$package_obj->name};
  foreach ( sort keys %{$my_descendants} ) {
    my $name = $_;
    $name = sprintf '<a href="%s">%s</a>', $module_cache->{$_}->doc_filename, $name
      if exists $module_cache->{$_};
    $c->add_entry( 'Children', $name ) if $my_descendants->{$_} == 2;
    $d->add_entry( 'Descendants', $name );
  }
  return Pagesmith::HTML::Tabs->new({'fake'=>1,})->add_classes('second-tabs')
    ->add_div_classes( 'hide-heading' )
    ->add_tab( 'children', 'Children', $c->render )
    ->add_tab( 'descendants', 'Descendants', $d->render )
    ->render;
}

sub generate_details {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate details tab
## * Lists rcs details, parent packages, used packages, constants and package variables
  my $package_obj = shift;
  my $html = $package_obj->format_description;
  my $twocol = Pagesmith::HTML::TwoCol->new;
     $twocol->add_entry( 'File', $package_obj->file->name );
  foreach my $k ('Author','Created','Maintainer','Last commit by','Last modified','Repository URL') {
    $twocol->add_entry( $k, $package_obj->rcs_keyword( $k ) || q(-) );
  }
  my $list_of_packages = [];
  if( $package_obj->parents ) {
    my %real_parents = map { ($_=>1) } $package_obj->parents;
    foreach my $package ( $package_obj->ancestors ) {
      my $name = $package;
      $name = "<em>$package</em>" unless exists $real_parents{$package};
      if( exists $module_cache->{$package}) {
        $name = sprintf '<a href="%s">%s</a>', $module_cache->{$package}->doc_filename, $name;
      }
      $twocol->add_entry( 'Ancestor(s)', $name )
    }
  }
  my %used = $package_obj->used_packages;
  if( keys %used ) {
    my $used = Pagesmith::HTML::TwoCol->new({'class'=>'evenwidth'});
    foreach my $package ( sort keys %used ) {
      my @methods = @{$used{$package}||[]};
      if( exists $module_cache->{$package}) {
        $package = sprintf '<a href="%s">%s</a>', $module_cache->{$package}->doc_filename, $package;
      }
      if( @methods ) {
        $used->add_entry( $package, $_ ) foreach @methods;
      } else {
        $used->add_entry( $package, q(-) );
      }
    }
    $twocol->add_entry( 'Uses', $used->render );
  }
  my %const = $package_obj->constants;
  if( keys %const ) {
    my $const = Pagesmith::HTML::TwoCol->new({'class'=>'twothird'});
    foreach my $name ( sort keys %const ) {
      $const->add_entry( $name, encode_entities($const{$name}) );
    }
    $twocol->add_entry( 'Constant', $const->render );
  }
  my %package_variables = $package_obj->package_variables;
  if( keys %package_variables ) {
    my $pv = Pagesmith::HTML::TwoCol->new({'class'=>'twothird'});
    foreach my $name ( sort keys %package_variables ) {
      $pv->add_entry( $name, encode_entities($package_variables{$name}) );
    }
    $twocol->add_entry( 'Package variables', $pv->render );
  }
  $html .= $twocol->render;
  return $html;
}

sub generate_summary {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate HTML for methods tab
  my $package_obj = shift;
  ## no critic (LongChainsOfMethodCalls)
  my @methods = $package_obj->methods;
  return q(<p>No functions in this package</p>) unless @methods;
  my $table = Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( ['all'] )
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name',                        'label' => 'Name',
        'link' => [ [ 'class=change-tab #method_[[h:name]]', 'exact', 'is_documented', 'Y' ] ],
      },
      { 'key' => 'is_documented',               'label' => 'Doc?',        'align'  => 'c' },
      { 'key' => 'is_method',                   'label' => 'Meth?',       'align'  => 'c' },
      { 'key' => 'format_parameters_short',     'label' => 'Parameters',  'format' => 'r' },
      { 'key' => 'format_return_short',         'label' => 'Return',      'format' => 'r' },
      { 'key' => 'format_description',          'label' => 'Description', 'format' => 'r' },
      { 'key' => 'location',                    'label' => 'Location',
        'link' => '#line_[[d:start]]',
        'template' => '[[d:start]]-[[d:end]]', 'align' => 'c' },
    )
    ->add_data( @methods );
  ## use critic
  return $table->render;
}

sub generate_summary_full {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate HTML for full method list
## * This includes all methods which are available from other Pagesmith packages

  my $package_obj = shift;
  ## no critic (LongChainsOfMethodCalls)
  my @methods = $package_obj->full_methods;
  return unless @methods;
  my $hidden  = $package_obj->hidden_methods;
  my $table = Pagesmith::HTML::Table->new
    ->make_sortable
    ->add_class( 'before narrow-sorted' )
    ->set_filter
    ->set_export( [qw(txt csv xls)] )
    ->set_pagination( [qw(10 20 50 100 all)], q(20) )
    ->make_scrollable
    ->set_current_row_class( sub {
      return exists $hidden->{ $_[0]->package_name }{ $_[0]->name } ? 'parent struck'
           : $_[0]->package_name ne $package_obj->name              ? 'parent'
           :                                                     q()
           ;
    })
    ->add_columns(
      { 'key' => q(#), },
      { 'key' => 'name',                        'label' => 'Name',
        'link' => sub {
           return q() unless $_[0]->is_documented eq 'Y';
           return sprintf '%s#method_%s',
             $_[0]->package_name eq $package_obj->name ? q() : 'rel=external '.$module_cache->{$_[0]->package_name}->doc_filename,
             $_[0]->name;
        } },
        #'link' => [ [ 'class=change-tab #method_[[h:name]]', 'exact', 'is_documented', 'Y' ] ] },
      { 'key' => 'is_documented',               'label' => 'Doc?',        'align'  => 'c' },
      { 'key' => 'is_method',                   'label' => 'Meth?',       'align'  => 'c' },
      { 'key' => 'format_parameters_short',     'label' => 'Parameters',  'format' => 'r' },
      { 'key' => 'format_return_short',         'label' => 'Return',      'format' => 'r' },
      { 'key' => 'format_description',          'label' => 'Description', 'format' => 'r' },
      { 'key' => 'location',                    'label' => 'Location',
        'link' => sub {
           return sprintf '%s#line_%d',
             $_[0]->package_name eq $package_obj->name ? q() : 'rel=external '.$module_cache->{$_[0]->package_name}->doc_filename,
             $_[0]->start;
        },
        'template' => '[[d:start]]-[[d:end]]', 'align' => 'c' },
      { 'key' => 'package_name',               'label' => 'Package',
        'template' => sub { return $_[0]->package_name eq $package_obj->name ? q(-) : $_[0]->package_name; },
      },
    )
    ->add_data( @methods );
  ## use critic
  return $table->render;
}

sub generate_methods {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate list of methods which have been documented - with "jDoc" style @params/@return comments
  my $package_obj = shift;
  my @methods = $package_obj->documented_methods;
  return '<p>No documented methods</p>' unless @methods;
  my $fake_tabs = Pagesmith::HTML::Tabs->new({'fake'=>1});
  foreach (@methods) {
    my $meth = Pagesmith::HTML::TwoCol->new;
    my $notes = $_->format_notes;
    $meth->add_entry( 'Type',       $_->method_desc );
    $meth->add_entry( 'Parameters', $_->format_parameters );
    $meth->add_entry( 'Returns',    $_->format_return );
    $meth->add_entry( 'Notes', $notes ) if $notes;
    ## no critic (ImplicitNewlines)
    $fake_tabs->add_tab(
      'method_'.$_->name, $_->name,
      $_->format_description.
      $meth->render.
      sprintf '<h4>Code</h4><div class="collapsible collapsed">
     <p class="head">Lines %d - %d <span class="show"> [show source code]</span><span class="hide"> [hide source code]</span>
     <pre class="code">%s</pre></div>
     <p><a href="#line_%s">View in main source code</a></p>', $_->start, $_->end, $_->code, $_->start,
    );
    ## use critic
  }
  return sprintf '<div class="sub_nav left"><h4>Methods</h4>%s</div><div class="sub_data">%s</div>',
    $fake_tabs->render_ul_block, $fake_tabs->render_div_block;
}

sub generate_notes {
#@params (Pagesmith::Utils::Documentor::Package package object)
#@return (string) HTML
## Generate contents of notes tab
  my $package_obj = shift;
  return $package_obj->format_notes;
}


## no critic (ImplicitNewlines)
sub generate_index_file {
  return q(
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <title>Perl doc index...</title>
<% CssFile /docs/perl/css/documentor.css /core/css/beta/nav.css %>
<% JsFile /docs/perl/js/documentor.js /core/js/beta/nav.js %>
</head>
<body id="documentor">
  <div id="main">
    <div class="panel">
      <h2>Perl modules</h2>
      <ul class="tabs">
        <li><a href="#tt_modules">Modules</a></li>
        <li><a href="#tt_methods">Methods</a></li>
      </ul>
      <div id="tt_modules">
        <h3>Modules</h3>
        <% File inc/module_list.inc %>
      </div>
      <div id="tt_methods">
        <h3>Methods</h3>
        <% File inc/method_list.inc %>
      </div>
    </div>
    <div class="panel">
      <div id="method_links"><p>Select a method from the list above to see which modules the method exists in</p></div>
    </div>
  </div>
  <div id="rhs">
    <div class="panel">
    <h3>Files</h3>
    <% File inc/list.inc %>
    </div>
  </div>
</body>
</html>
);
}

sub generate_css_file {
  return q(
#documentor #main { width: 67%; }
#documentor #rhs  { width: 32%; }

.parent td { font-style: italic }
.struck { text-decoration: line-through }
#rhsx { display: none }
#mainx { width: 100% }
.toggle-width { float: right; background-color: #ccc; color: #000; font-size: 50%; padding: 2px 2em; margin-left: 2em }
);
}

## no critic (InterpolationOfMetachars)
sub generate_js_file {
  return q(
$('#wrap').on('click','a[href^="#line_"]',function() {
  $('a[href="#source"]').click();
  return 1;
});

$('body')
  .on('click','#main  .toggle-width',function() { $('#main').attr('id','mainx'); $('#rhs').attr('id','rhsx'); $(this).html('&gt;=&lt;');} )
  .on('click','#mainx .toggle-width',function() { $('#mainx').attr('id','main'); $('#rhsx').attr('id','rhs'); $(this).html('&lt;=&gt;');} );

var id_str = window.location.hash;
if (id_str && id_str.match(/^#line_(\d+)$/)) {
  $('a[href="#source"]').click();
  window.location.hash = id_str;
  if( $(id_str).get(0).scrollIntoView ) {
    $(id_str).get(0).scrollIntoView();
  }
  // Now we have to achieve a scroll to!
}

$('#wrap').on('click','.method_list',function() {
  console.log( "METHOD" );
console.log( $(this) );
  var name = $(this).prop('hash').substr(1);
  console.log( name );
  $('#method_links').html('<div class="ajax" title="/component/File?pars=-ajax%20%2Fdocs%2Fperl%2Finc%2Fmethod_links%2F'+name+'.inc"><p>Fetching lists</p></div>');
});
);
}
## use critic

__END__

Script Usage
============

    utilities/documentor.pl [--site|-s {sitename}] [--path|-p {path}]

Command line options
====================

|Option|Description|Flag|Default|
|-----:|-----------|:--:|-------|
|--site|Site to generate documentation into|optional|apps.sanger.ac.uk|
|--path|Directory to generate documentation into|optional|docs/perl|

Description
===========

Looks through all top-level (lib/utilities & {xx}/lib & {xx}/utilities) and
site specific perl folders (sites/{xx}/lib, sites/{xx}/cgi, sites/{xx}/perl,
sites/{xx}/utilities) to generate documenation for them.

Output is generated in folder sites/{sitename}/htdocs/{path}

Documentation style
===================

All modules/scripts should have the following boiler plate at the start:

    ## Retrieve documentation for all perl files...

    ## Author         : js5
    ## Maintainer     : js5
    ## Created        : 2012-11-19
    ## Last commit by : $Author$
    ## Last modified  : $Date$
    ## Revision       : $Revision$
    ## Repository URL : $HeadURL$

Function documentation is in the form of #@/## comments just after the "sub name {" line

* #@params (type name - description)[?+*]
    * e.g.
        + #@params (self) (Pagesmith::Adaptor DB adaptor) (int user id - User's ID from session cookie)?
    * type - type of variable
        + pipe separated if can take multiple types
        + hashref of a given type can be written as type{}
        + arrayref of a given type can be written as type[]
        + hashref/arrayref used for more general data-structures
    * name - string to describe variable - keep it short
    * description - optional - longer description of variable/notes
    * flag - ?, +, * - optional / multi-valued flag
* #@param (type)[?+*] name - description
    * Note one line per parameter
    * e.g.
        + #@param (self)
        + #@param (Pagesmith::Adaptor) DB adaptor
        + #@param (int)? user id - User's ID from session cookie
    * as above
* #@returns (type description)[?+*] 
    * Value/object returned
    * e.g.
        + #@returns (Pagesmith::Adaptor DB adaptor) (int User's ID from session cookie)
    * see notes for @params - note doesn't have name in definition
* #@return (type)[?+*] description
    * Note one line per value/object
    * Value/object returned
    * see notes for @params - note doesn't have name in definition
* #@class (type)
    * description of method as either Getter, Setter or Accessor
* ## - general documentation - note this is split into a single paragraph description - followed by futher notes
    * uses [MultiMarkdown][]
    * See [MultiMarkdown user guide][]

Additional documentation can be included after an "\_\_END\_\_" line - again using MultiMarkdown

Notes
=====

* Index, CSS and JavaScript files are generated only if they don't already
  exist

[MultiMarkdown]: http://fletcherpenney.net/multimarkdown/
[MultiMarkdown user guide]: http://fletcher.github.com/peg-multimarkdown/mmd-manual.pdf
