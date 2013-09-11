
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
