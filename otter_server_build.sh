#! /bin/sh

# This is rough and ready.  Something of a "how it could work" if we
# wanted it like this.
#
# cd to anywhere, or the ensembl-otter clone you would use as source.
# Run this file by its path within the webvm clone you want updated.
#
# Expects relevant bits of team_tools.git to be on PATH.

set -e
unset CDPATH


# Take server code from?
REPO_URL=intcvs1:/repos/git/anacode/ensembl-otter.git
REPO_NAME=intcvs1
if [ -d ".git" ] && [ -f "dist/conf/version_major" ]; then
    # Looks like a dev copy.  Clone that instead.
    REPO_URL="$PWD"
    REPO_NAME=workdir
    : ${BUILD_VSNS:=$( git branch | perl -ne 's/\*//; print if m{\b(master|humpub-branch-\d+)\b}' )}
fi

# XXX: something smarter, based on designations.txt ?
: ${BUILD_VSNS:=humpub-branch-72 humpub-branch-73 master}

# Build into the nearby {cgi-bin,lib}/
OTT_DEST="$( cd $( dirname $0 ); pwd )"



# Manage a temporary git clone
EOCLONE="$( mktemp -d --tmpdir=/dev/shm ens-ott-serv.XXXXXX )"
eoclone_cleanup() {
    if [ -n "$EOCLONE" ] && [ -d "$EOCLONE/.git" ] && [ -f "$EOCLONE/dist/conf/version_major" ]; then
        printf '\nTidying up\n'
        rm -rf "$EOCLONE"
    else
        printf '\nNot tidying up "%s", looks funny\n' "$EOCLONE"
        # it might be an emptydir if clone failed,
        # otherwise we're lost and should not be -rf'ing anything
        rmdir "$EOCLONE"
    fi
}
trap 'eoclone_cleanup' EXIT



# Tell what's happening, then do it
echo "Going to build to $OTT_DEST/ versions ($BUILD_VSNS)
  via checkout in $EOCLONE
      cloned from $REPO_URL"

printf '\nCloning ... '
git clone -o $REPO_NAME -q $REPO_URL "$EOCLONE"
echo
cd "$EOCLONE"

# detached head
git checkout -q $( git log -1 --format=%H HEAD )

sedent(){
    sed -e 's/^/  /'
}

for VSN in $BUILD_VSNS; do
    printf '\n\n\nBuilding for %s\n' "$VSN"
    cd "$EOCLONE"
    rev=$REPO_NAME/$VSN
    if git reset -q --hard $rev; then
        git log -1 --format=fuller --decorate | sedent
        export otter_nfswub="$OTT_DEST"
        logfile="$( mktemp --tmpdir=$EOCLONE build-log.$VSN.XXXXXX )"
        if otterlace_build --server-only > $logfile 2>&1; then
            echo OK
        else
            cat $logfile | sedent
            echo $VSN failed >&2
            exit 2
        fi
    else
        echo "Skip: build for $VSN because $rev not found"
    fi
done


stale=$(
    find $OTT_DEST/lib/otter $OTT_DEST/cgi-bin/otter \
        -maxdepth 1 ! -newer $EOCLONE/.git/config -ls 2>&1
)
if [ -n "$stale" ]; then
    printf '\n\nW: stale server versions exist and were not touched\n'
    printf '%s' "$stale" | sedent
else
    echo All server versions updated
fi
