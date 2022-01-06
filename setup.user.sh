#! /bin/sh
# Copyright [2018-2022] EMBL-European Bioinformatics Institute
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


# Install an empty "WTSI Web VM" style user area
# and dependency libraries


# Takes environmental overrides
: ${WEBDIR:=/www}
: ${FOR_USER:=$USER}
: ${WEBVM:=intcvs1:/repos/git/anacode/webvm.git}
: ${WDEPS:=intcvs1:/repos/git/anacode/webvm-deps.git}
: ${HTTPD:=intcvs1:/repos/git/anacode/httpd.git}

: ${INSTALL_TO:=$WEBDIR/$FOR_USER/www-dev}
: ${STATEDIR:="$WEBDIR/tmp/$FOR_USER"}


# XXX:DUP from APACHECTL
APACHE2=/usr/sbin/apache2


if [ -e "$INSTALL_TO/.git" ]; then
    echo "Abort: $INSTALL_TO/.git exists" >&2
    exit 2
fi


if [ -d "$INSTALL_TO" ] && [ -w "$INSTALL_TO" ]; then
    echo "$INSTALL_TO is ready to write"
else
    echo "
Abort: cannot write into directory $INSTALL_TO

Please provide it (by running ./setup.root.sh) or
supply an alternative such as
  INSTALL_TO=~/_httpd STATEDIR=/var/tmp/$USER.apache2/portnumber $0
" >&2
    exit 3
fi


# We use STATEDIR for logs, pids and any other tmpfiles to ease
# webteam clone of a server - they exclude it and make a blank on on
# the target.
#
# Some files stored here insist on being on local disk.

mkdir -p -v "$STATEDIR/logs" || {
    echo "Abort: canot mkdir $STATEDIR{,/logs}

You must make them on local storage
and configure via APACHECTL.sh
" >&2
    exit 4
}


set -e
printf "\n** Apache config & bootstrap: %s\n   nb. requires empty %s\n" \
    "$WEBVM" "$INSTALL_TO"
git clone "$WEBVM" "$INSTALL_TO"
printf "\n** Large Perl libs: %s\n" "$WDEPS"
git clone "$WDEPS" "$INSTALL_TO/apps/webvm-deps"

if [ -x "$APACHE2" ]; then
    echo "Found httpd at $APACHE2"
else
    printf "\n** Fetch httpd (%s was not found)\n" "$APACHE2"
    git clone "$HTTPD" "$INSTALL_TO/httpd"
    echo "
You may need to branch the configuration to support this httpd
" >&2
fi


echo "Complete."
