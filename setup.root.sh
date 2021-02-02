#! /bin/sh
# Copyright [2018-2021] EMBL-European Bioinformatics Institute
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


# Make a "WTSI Web VM" style user area
#
# You may also need to
#   sudo aptitude install apache2-mpm-prefork


# Takes an environmental override
: ${WEBDIR:=/www}


case "$SUDO_USER::$1" in
    :: | ::-h | ::--help | *::-h | *::--help)
	echo "Syntax: $0 [ <username> ]

This does
  mkdir -p \$WEBDIR/{tmp/,}\$USERNAME
  chown ...

Username can be detected from sudo(8), else must be specified.

\$WEBDIR is $WEBDIR but may be overridden by setting the environment
variable.
" >&2
	exit 1
	;;
    *::)
	FOR_USER="$SUDO_USER"
	;;
    *::*)
	FOR_USER="$1"
	;;
esac

if [ "$USER" != 'root' ]; then
    echo "[w] Looks like you are running as $USER"
    echo "    $0 needs to be root unless you can write $WEBDIR"
fi >&2

if [ -e "$WEBDIR/$FOR_USER" ]; then
    echo "Abort: $WEBDIR/$FOR_USER exists" >&2
    exit 2
fi

echo "Making userspace in $WEBDIR/$FOR_USER" >&2
mkdir -p "$WEBDIR" "$WEBDIR/$FOR_USER" "$WEBDIR/tmp/$FOR_USER"
chown $FOR_USER:$FOR_USER "$WEBDIR/$FOR_USER" "$WEBDIR/tmp/$FOR_USER"
