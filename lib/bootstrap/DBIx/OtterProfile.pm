=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package DBIx::OtterProfile;
use strict;
use warnings;

use base 'DBI::ProfileDumper';

=head1 NAME

DBIx::OtterProfile - local DBI::ProfileDumper subclass

=head1 SYNOPSIS

Write into F<apps/99profile.conf>

  <Location "/cgi-bin/otter/86/">
      SetEnv DBI_PROFILE {Name}:!Statement:!Caller2/DBIx::OtterProfile/Dir:/tmp/myprofiles/
  </Location>
  TimeOut 900

and run F<utilities/restart>

=head1 DESCRIPTION

Configures L<DBI::ProfileDumper> to put files in a directory by PID.
The named directory must exist and be writable.

Examine the output with L<dbiprof(1)>.

=cut

sub new {
    my ($pkg, %arg) = @_;
    if (my $dir = delete $arg{Dir}) {
        die "$pkg(Dir => $dir) not a directory" unless -d $dir;
        $arg{File} = "$dir/dbi.prof.$$";
    }
    return $pkg->SUPER::new(%arg);
}

sub _detaint {
    my ($called) = @_;
    return unless defined $ENV{DBI_PROFILE};

    # There will be slashes in it - it won't work without a subclass,
    # because DBI::Profile formatter chokes on tainted $0

    my $val = $ENV{DBI_PROFILE};
    my ($paths, $pkg, $args) = $val =~
      m{^([^/])*/(DBIx?::[A-Za-z]*Profile[:A-Za-z]*)/(.*)$}
        or die "detaint $val failed";
    # paths & args are more complex, but don't allow code loading

    my $DBI_PROFILE = join '/', $paths, $pkg, $args;

    # Do what DBI.so does here instead, because %ENV would re-taint our text
    delete $ENV{DBI_PROFILE};
    $DBI::shared_profile ||= $pkg->_auto_new($DBI_PROFILE);

    return;
}

__PACKAGE__->_detaint;

1;
