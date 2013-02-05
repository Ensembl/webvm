#! /bin/sh

# This is rough and ready.  Something of a "how it could work" if we
# wanted it like this.
#
# cd to anywhere, or the ensembl-otter clone you would use as source.
# Run this file by its path within the webvm clone you want updated.

set -e
unset CDPATH


# Take server code from?
REPO_URL=intcvs1:/repos/git/anacode/ensembl-otter.git
if [ -d ".git" ] && [ -f "dist/conf/version_major" ]; then
    # Looks like a dev copy.  Clone that instead.
    REPO_URL="$PWD"
fi

: ${BUILD_VSNS:=humpub-branch-71 humpub-branch-72 master}

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
git clone -q $REPO_URL "$EOCLONE"
echo
cd "$EOCLONE"
git checkout -b server_build_tmp

for VSN in $BUILD_VSNS; do
    printf '\n\n\nBuilding for %s\n' "$VSN"
    cd "$EOCLONE"
    git reset --hard origin/$VSN || \
        git reset --hard 
    otter_nfswub="$OTT_DEST" otterlace_build --server-only
done
