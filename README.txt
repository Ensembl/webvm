-*- org -*-

In Emacs & new to org-mode?  Move to Documentation line and hit TAB
twice.  Heading levels are indicated by lines =~ m{^\*+}

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
chasing out the Ubuntu dependencies.


Then you
  # repo override only needed until it moves to team area
  WEBVM=intcvs1:/repos/git/users/mca/webvm.git \
  ./setup.user.sh

*** What should it do?
Run for anyone, independent of location, like this

 /usr/sbin/apache2ctl -d /www/$USER/ServerRoot

which is cumbersome, so use

 /www/$USER/start
 /www/$USER/stop

Possible actions/options for that script are likely to change.

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
    git grep -hE '[X]XX:|[B]0RK/' | sed -e 's/^[ #]*//; s/XXX/XX/; s/^/  /' | sort -uf

  "/ServerRoot_B0RK/cgi-bin" should be changed to whatever your ScriptAliased
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
  server as "/ServerRoot_B0RK/logs/foo_log".
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
  XX:LOCALMOD symlink ServerRoot/logs to user's tmpdir.

*** XXX:TODO tell CGI scripts when request is internal
Need to check or replace the HTTP_CLIENTREALM mechanism, used by $erverScriptSupport->local_user

*** XXX:TODO trigger DEVEL mode
based on what,
 the hostname?
 (untracked or locally modified) config file?
 being a user not www-anacode?
