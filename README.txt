-*- org -*-
#+STARTUP: showall

Heading levels are indicated by lines =~ m{^\*+}

* Documentation
** What is this config?
This is Apache2 configuration for Anacode web virtual machines.
It aims to serve dev & live use for anyone in the team.

Further notes are at
  http://mediawiki.internal.sanger.ac.uk/wiki/index.php/Anacode:_Web_VMs

*** Where did it come from?
The Git history shows the details.

It is based on a build-from-tarball Apache 2.2.17 plus modifications
until it looks likely to behave for our purposes.

*** How do I install it?
Assuming you have the latest setup.*.sh scripts handy and wish to
install files for your own area:


If you are root (e.g. install to laptop), use

 sudo ./setup.root.sh

 sudo aptitude install apache2-mpm-prefork # Linux
 sudo port -v install apache2 +preforkmpm  # MacPorts - mca's guess

Otherwise you need root to do the equivalent operations, and/or
install from tarball and set up in your home directory.

Note that running on Mac is not (yet) supported and would require
chasing out the Ubuntu dependencies.  Some of these are marked with
[X]XX:UBUNTU.


Then you
  # repo override only needed until it moves to team area
  WEBVM=intcvs1:/repos/git/users/mca/webvm.git \
  ./setup.user.sh

*** What should it do?
Run for anyone, independent of location, like this

 /usr/sbin/apache2ctl -f /www/$USER/ServerRoot/conf/httpd.conf ...

which is cumbersome, so use

 /www/$USER/start
 /www/$USER/stop

Possible actions/options for that script are likely to change.

** Environment variables
*** WEBDIR
WEBDIR points to the git working copy.  It contains your ServerRoot,
htdocs etc..

This variable is built from $0
*** WEBTMPDIR
By the web team's convention, host-specific writable files are kept
separate.  This makes it clear what files should not be copied, when
cloning a machine.  WEBTMPDIR is that directory.

It defaults to something like /www/tmp/$USER but is derived from
WEBDIR, unless a value is passed in.
*** WEBDEFS
WEBDEFS takes comma-separated keywords to pass as "apache2 -D" flags.

It currently defaults to "vanilla", but this may change.

Useful options are
+ DEVEL :: enable the server-status & server-info pages.  This comes from our config.
+ DEBUG :: to run a single Apache thread and stop it going into the background.  This is an Apache option.

** ServerConf/conf/ contents
*** What is /ServerRoot_B0RK ?
The Apache build process hardwires various filenames into the config
it generates.

I replaced (15474d66639df5ec8f558b30e930e6102c765156) these paths with
something apparently valid but not existing on the filesystem.

This prevents accidental dependency on something we should not be
using and makes for an easy grep token.

Then I started replacing them with things that work.

*** Fixmes and grubbiness that may be worth improving later
    git grep -hE '[X]XX:|[B]0RK/|[T]ODO' | sed -e 's/^[ #]*//; s/XXX/xXX/; s/[T]ODO/tODO/; s/^/  /' | LC_ALL=C sort -uf

  *** tODO tell CGI scripts when request is internal
  *** tODO trigger DEVEL mode
  /ServerRoot_B0RK/error/include/ files and copying them to /your/include/path/, 
  <Directory "/ServerRoot_B0RK/cgi-bin">
  <Directory "/ServerRoot_B0RK/error">
  <Directory "/ServerRoot_B0RK/manual">
  <Directory "/ServerRoot_B0RK/uploads">
  Alias /uploads "/ServerRoot_B0RK/uploads"
  AliasMatch ^/manual(?:/(?:de|en|es|fr|ja|ko|pt-br|ru|tr))?(/.*)?$ "/ServerRoot_B0RK/manual$1"
  AuthUserFile "/ServerRoot_B0RK/user.passwd"
  CustomLog "/ServerRoot_B0RK/logs/ssl_request_log" \
  DavLockDB "/ServerRoot_B0RK/var/DavLock"
  DocumentRoot "/ServerRoot_B0RK/docs/dummy-host.example.com"
  DocumentRoot "/ServerRoot_B0RK/docs/dummy-host2.example.com"
  DocumentRoot "/ServerRoot_B0RK/htdocs"
  ErrorLog "/ServerRoot_B0RK/logs/error_log"
  htdigest -c "/ServerRoot_B0RK/user.passwd" DAV-upload admin
  SSLCACertificateFile "/ServerRoot_B0RK/conf/ssl.crt/ca-bundle.crt"
  SSLCACertificatePath "/ServerRoot_B0RK/conf/ssl.crt"
  SSLCARevocationFile "/ServerRoot_B0RK/conf/ssl.crl/ca-bundle.crl"
  SSLCARevocationPath "/ServerRoot_B0RK/conf/ssl.crl"
  SSLCertificateChainFile "/ServerRoot_B0RK/conf/server-ca.crt"
  SSLCertificateFile "/ServerRoot_B0RK/conf/server-dsa.crt"
  SSLCertificateFile "/ServerRoot_B0RK/conf/server.crt"
  SSLCertificateKeyFile "/ServerRoot_B0RK/conf/server-dsa.key"
  SSLCertificateKeyFile "/ServerRoot_B0RK/conf/server.key"
  SSLMutex  "file:/ServerRoot_B0RK/logs/ssl_mutex"
  SSLSessionCache         "dbm:/ServerRoot_B0RK/logs/ssl_scache"
  SSLSessionCache        "shmcb:/ServerRoot_B0RK/logs/ssl_scache(512000)"
  TransferLog "/ServerRoot_B0RK/logs/access_log"
  xXX:UBUNTU GNU-ism.


*** TODO tell CGI scripts when request is internal
Need to check or replace the HTTP_CLIENTREALM mechanism, used by $erverScriptSupport->local_user

*** TODO trigger DEVEL mode
based on what,
 the hostname?
 (untracked or locally modified) config file?
 being a user not www-anacode?

It may be set manually with WEBDEFS=DEVEL

*** TODO Set MaxClients in conf/extra/httpd-mpm.conf
jh13 comments "MaxClients 150" to avoid bringing the machine down

*** TODO rescue content from intweb
+ [ ] /nfs/WWWdev/INTWEB_docs/htdocs/Teams/Team71/vertann
+ [ ] /nfs/WWWdev/INTWEB_docs/cgi-bin/users
  - [ ] jh13
  - [ ] mca
  - [ ] jgrg
  - [ ] ml6
  - [ ] ck1

*** TODO avoid tripping Bio::Otter::Git up, by deploying via a git repo
+ jh13 would be happy to have B:O:G (caching mechanism?) replaced with something better

** Git branch structure
Initial plan...

 master		Minimal Apache config and consensus set of tools.
		This branch should be useful for merge into any other.

 $USER or
 $USER/*	your stuff
		  e.g. mca/sandbox mca/deskpro

 www-anacode	One branch for both dev & live, because
		we have internal structure to separate them


$USER branches which collect a large number of commits for dev
Otterlace builds could be reset by

 a) cherry pick or otherwise copy useful stuff onto master or
    $USER/master

 b) rewind the branch on intcvs1 to master or $USER/master

 c) have the deployment scripts accept forced updates
