#! /bin/sh

# Install an empty "WTSI Web VM" style user area


# Takes environmental overrides
: ${WEBROOT:=/www}
: ${FOR_USER:=$USER}
: ${WEBVM:=intcvs1:/repos/git/anacode/webvm.git}


if [ -e "$WEBROOT/$FOR_USER/.git" ]; then
    echo "Abort: $WEBROOT/$FOR_USER/.git exists" >&2
    exit 2
fi

git clone "$WEBVM" "$WEBROOT/$FOR_USER"

# XXX:LOCALMOD symlink ServerRoot/logs to user's tmpdir.
#
# We use that tmpdir for logs, pids and any other tmpfiles to ease
# webteam clone of a server - they exclude it and make a blank on on
# the target.
#
# There may be a neater way to point there (like "apache2 -c"?) but
# this is good enough for now.
#
# Some files stored here insist on being on local disk.

LOGDIR="$WEBROOT/tmp/$FOR_USER/logs"
mkdir -p -v "$LOGDIR"
ln -s -v "$LOGDIR" "$WEBROOT/$FOR_USER/ServerRoot/logs"
