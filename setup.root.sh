#! /bin/sh

# Make a "WTSI Web VM" style user area
#
# You may also need to
#   sudo aptitude install apache2-mpm-prefork


# Takes an environmental override
: ${WEBROOT:=/www}


case "$SUDO_USER::$1" in
    :: | ::-h | ::--help | *::-h | *::--help)
	echo "Syntax: $0 [ <username> ]

Username can be detected from sudo(8), else must be specified." >&2
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
    echo "    $0 needs to be root unless you can write $WEBROOT"
fi >&2

if [ -e "$WEBROOT/$FOR_USER" ]; then
    echo "Abort: $WEBROOT/$FOR_USER exists" >&2
    exit 2
fi

echo "Making userspace in $WEBROOT/$FOR_USER" >&2
mkdir -p "$WEBROOT" "$WEBROOT/$FOR_USER" "$WEBROOT/tmp/$FOR_USER"
chown $FOR_USER:$FOR_USER "$WEBROOT/$FOR_USER" "$WEBROOT/tmp/$FOR_USER"
