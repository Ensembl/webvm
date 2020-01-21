# Copyright [2020] EMBL-European Bioinformatics Institute
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


  PATH=~/bin:/software/bin:/usr/bin:/bin

  # OSperl is too old and /software/perl-* exists here
  PATH=/software/perl-5.12.2/bin:$PATH
  OTTER_PERL_EXE=$(which perl)

  # locks & logs in here; must mkdir it first
  WEBTMPDIR=/var/tmp/$USER.apache2/8002
  mkdir -p $WEBTMPDIR/logs

  BUILT=$WEBDIR/httpd

  # needed also for tools/*
  APACHE2_MODS=$BUILT/modules
  APACHE2_SHARE=$BUILT

  # do this early to preserve pattern below
  LD_LIBRARY_PATH=$BUILT/lib

  # pass only the necessary environment
# TODO: Push environment cleaning up to APACHECTL, so it happens in production also
  APACHE2=$( echo env -i \
      PATH=$PATH \
      USER=$USER \
      WEBDIR=$WEBDIR \
      WEBTMPDIR=$WEBTMPDIR \
      LD_LIBRARY_PATH=$LD_LIBRARY_PATH \
      APACHE2_MODS=$APACHE2_MODS \
      APACHE2_SHARE=$APACHE2_SHARE \
      OTTER_PERL_EXE=$OTTER_PERL_EXE \
      $BUILT/bin/httpd
  )
#  printf "[d] APACHE2=%s\n" "$(echo $APACHE2 | sed -e 's/ /\n\t/g' )"
#  printf "[d] Using Perl=%s\n" "$(which perl)"

WEBDEFS=deskpro,devel
