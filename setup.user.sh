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

# We use that tmpdir for logs, pids and any other tmpfiles to ease
# webteam clone of a server - they exclude it and make a blank on on
# the target.
#
# Some files stored here insist on being on local disk.

LOGDIR="$WEBROOT/tmp/$FOR_USER/logs"
mkdir -p -v "$LOGDIR"
