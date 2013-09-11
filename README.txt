-*- org -*-
#+STARTUP: showall

Heading levels are indicated by lines =~ m{^\*+}

* Documentation
** What is this config?
This project contains an Apache2 configuration suitable for dev (on
deskpro or laptop) and live use (on virtual machine), including
+ an httpd.conf laced with "Include"s and ${ENVIRONMENT_VARIABLE} substitutions
+ supporting shell script
+ Perl libraries to bootstrap the provision of APIs needed by the Otter Server
+ Perl libraries to support internal development

Other components it does not contain but can bring in are
+ the httpd, by default from an Ubuntu package
+ larger Perl libraries (webvm-deps.git)
  - WTSI Single Sign On
  - Ensembl
  - BioPerl

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

 # Provide Apache httpd from OS (optional)
 sudo aptitude install apache2-mpm-prefork # Linux
 sudo port -v install apache2 +preforkmpm  # MacPorts - mca's guess


Then install the config and (large!) Perl libraries
  ./setup.user.sh
  # this script could use some polish, but I don't expect to use it often


(Optional) build httpd from tarball
  cd $WEBDIR
  rm -rf httpd
  ln -s ~/my-httpd/ httpd
  # or otherwise make available
**** Running under MacOS X
Note that running on Mac is not (yet) supported and would require
chasing out the Ubuntu dependencies.  Some of these are marked with
[X]XX:UBUNTU.
*** What should it do?
Run for anyone, independent of location, like this

 /usr/sbin/apache2ctl -f /www/$USER/ServerRoot/conf/httpd.conf ...

which is cumbersome, so use

 /www/$USER/start
 /www/$USER/stop

Possible actions/options for that script are likely to change.

The easiest way to add new operations (which need to share config) is
to put them in tools/ .
** Which httpd?
*** Ubuntu Lucid
Use of /usr/sbin/apache2 is the default, to match the production web
servers.
*** Reasons to share httpd builds
+ Builds take time, and we can reuse them portably (per arch)
+ Configuration has many options, and the defaults are wrong
+ making the LoadModule directives match
  - modules come from the build, as defined by ./configure
  - LoadModule directives come with webvm.git
  - keeping them in sync is messy, but try "./APACHECTL checkmods"
+ So Macs & deskpros can have matching httpd
*** Run with home-installed / local Apache
You can run with a locally built and installed Apache, provided it
includes the necessary features.  Note that the default build does not
include mod_rewrite.

You can (p)reset the environment seen by the first call to apache2 by
writing to the file APACHECTL.sh .  This file is listed in .gitignore,
is sourced by APACHECTL and does not need to be executable.

This is useful for running with a locally installed Apache2 binary.
See branch mca/deskpro for how I do it.

**** Accumulated wisdom for ./configure of 2.2.x
Configurations used in the past,
+ ./configure --prefix=$HOME/_httpd --exec-prefix=$HOME/_httpd/i386 && make && make install
  - lacks mod_rewrite
  - putting binaries down a level might allow Mac support, but I didn't use that
  - mca first "local Apache"
+ ./configure --enable-rewrite --enable-so  --with-mpm=prefork --prefix=$HOME/_httpd/httpd --enable-pie  --enable-mods-shared=most
  - PIE is for security (location in memory is randomised)
  - these enable switches may be redundant
  - attempt to use for webvm
** Environment variables for web server
Apache's configuration files will interpolate ${ENVIRONMENT_VARIABLES}
like that.  This avoids having to write them with a template to
hardwire paths (as the shipped default seems to be).
*** APACHE2_MODS
The path to files for the LoadModule directive.
Default is for Ubuntu.
*** APACHE2_SHARE
The path to icons and errors.
Default is for Ubuntu.
*** WEBDIR
WEBDIR points to the git working copy.  It contains your ServerRoot,
htdocs etc..

This variable is built from $0
*** WEBTMPDIR
By the Web Team's convention, host-specific writable files (including
logs and lockfiles) are kept separate.  This makes it clear what files
should not be copied, when cloning a machine.

WEBTMPDIR is Anacode's name for that directory.  It defaults to
something like /www/tmp/$USER , being derived as a niece of WEBDIR.
An override value may be passed in or set from APACHECTL.sh .

This directory must exist, be writable and stored on local filesystem.
*** Not exported to httpd
These variables are used within the APACHECTL script
**** APACHE2
The path to the apache2 httpd executable, in the context of the
prevailing $PATH .  Default is for Ubuntu.

This is word expanded before use, so can also do environment setup.
**** op
The operation APACHECTL is about to perform.
**** WEBDEFS
WEBDEFS takes comma-separated keywords to pass as "apache2 -D" flags.

It currently defaults to "vanilla", but this may change.

Useful options are
+ DEVEL :: enable the server-status & server-info pages.  This comes from our config.
+ DEBUG :: to run a single Apache thread and stop it going into the background.  This is an Apache option.

** Perl environment for Otter Server
*** TL;DR
+ Our CGI scripts now take detainted @INC elements from $OTTER_PERL_INC
  - http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/ensembl-otter.git;h=be62b9f1
  - webvm.git/lib/bootstrap/ contains minimal initialisation code
+ They run under /usr/bin/perl directly
  - http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/ensembl-otter.git;h=3c761714
  - this generally gives us 5.10.1 but could change with OS upgrade
+ Configure to override the shebang Perl for development on deskpros
  (where /usr/bin/perl has no DBI.pm, or you )
  - OTTER_PERL_EXE=/software/bin/perl-5.12.2
  - http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/webvm.git;h=82d8a3a0
  - First developed near the cgi_wrap code,
    http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/team_tools.git;a=history;f=otterlace/server/perl/SangerPaths.pm;hb=647b3fcf
+ webvm-deps.git contains Ensembl API etc. which were previously
  provided by the web team.
  - beware, this repository contains large commits which can break
    gitk's display of patches
  - Otter::Paths expects it to be provided as $WEBDIR/apps/webvm-deps/
    but will also accept the webteam supplied copies
+ Existing "otterlace in local Apache on a deskpro" with
  otterlace_cgi_wrap continues to work, but is superseded
*** @INC and taint mode
The main problem is configuring our @INC while also enabling taint
mode.

+ we run root's Perl but we are not root, so we cannot add modules to the existing @INC
+ taint mode means we cannot add too @INC from the environment
+ a wrapper script between httpd and Perl (to run "perl -T -I... $script") works
  - it adds complexity
  - there may be a small performance penalty
  - isn't clean enough to run in production
  - we don't need to keep it in the long term
+ self-wrapping Perl scripts can do it
  - Perl starts untainted
  - use a module to find the libs and "exec $^X -I... -T $0" unless ${^TAINT}
  - neat but slightly slower (+0.0043s real time)
  - a chance to forget to run in taint mode
  - code checkers looking for "#! perl -T" won't see it
*** Which Perl to run?
Options for Perl are
1) /usr/bin/perl (OS Perl)
2) /software/perl-*/bin/perl .  Not available on web VMs.
3) /usr/local/bin/perl (may point to OS Perl or /software)
4) compile or install our own, with attendant libraries.

Until Otter v67 we used /usr/local/bin/perl which points to OS Perl on
webservers, /software/perl-5.8.8 on deskpro (local Apache) via
/software/bin/perl symlink.

Options for choosing Perl are
1) hardwired #! line (one size fits all)
2) hardwired #! line (script installer overwrites it)
3) #!/usr/bin/env perl (not compatible with "perl -T")
4) scripts can self-wrap when they don't like their environment

For production servers we want a hardwired #! for simplicity.
Development servers can self-wrap when configured to do so.
*** Environments to support - details
**** perl on intwebdev & others
Current (2012-06) live webservers find Otter Server like this.

+ scripts have #!/usr/local/bin/perl -Tw
  - calls /usr/bin/perl which is 5.8.8
+ @INC contains
  - /etc/perl
  - /usr/local/lib/perl/5.8.8
  - /usr/local/share/perl/5.8.8
  - /usr/lib/perl5
  - /usr/share/perl5
  - /usr/lib/perl/5.8
  - /usr/share/perl/5.8
  - /usr/local/lib/site_perl
+ script uses SangerPaths to add to @INC
  - /usr/lib/perl/5.8/SangerPaths.pm takes config from the webteam, of which we use (some of)
    - core :: /WWW/SHARED_docs/lib/core /WWW/SANGER_docs/perl /WWW/SANGER_docs/bin-offline (plus /usr/local/oracle/lib)
    - bioperl123 :: /WWW/SHARED_docs/lib/bioperl-1.2.3
    - ensembl65  :: /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-draw/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-variation/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-compara/modules /WWW/SHARED_docs/lib/ensembl-branch-65/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-external/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-pipeline/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-webcode/modules /WWW/SHARED_docs/lib/ensembl-branch-65/ensembl-functgenomics/modules
    - otter$N :: /WWW/SANGER_docs/lib/otter/$N
  - root put that there, we don't (in general) have that option
**** Otter Server on local Apache (2011 vintage)
In order to run existing code on local Apache, we did (in pseudo-code
and omitting error handling etc.) this,

+ httpd.conf uses
  - SetEnv to supply OTTERLACE_SERVER_ROOT and proxy settings
  - ScriptAliasMatch to send requests through team_tools/otterlace/server/cgi-bin/cgi_wrap
+ cgi_wrap
  - inspects $REQUEST_URI
  - locates the real CGI script under configured $OTTERLACE_SERVER_ROOT
  - runs team_tools/otterlace/server/bin/otterlace_cgi_wrap
+ otterlace_cgi_wrap
  - locates team_tools/otterlace/server/perl/
  - adds that and /software/anacode/lib{/site_perl} to @INC using "perl -I"
  - runs the real CGI script under "perl -T"
+ team_tools/otterlace/server/perl/ contains "fake" modules
  - SangerPaths.pm ::
    - provides requested libraries, from the subset we need
    - patch up %ENV to meet expectations of Bio::Otter::ServerScriptSupport
    - pass $OTTERLACE_ERROR_WRAPPING_ENABLED to B:O:SSS
  - SangerWeb.pm :: provides the minimum we need, with "always enabled" authentication
**** web-ottersand01
The environment is more restrictive,

+ /software does not exist in production
+ /usr/local/bin/perl points to /software/bin/perl (does not exist)
+ /usr/bin/perl is Ubuntu OS Perl, 5.10.1
+ vanilla @INC is
  - /etc/perl
  - /usr/local/lib/perl/5.10.1
  - /usr/local/share/perl/5.10.1
  - /usr/lib/perl5
  - /usr/share/perl5
  - /usr/lib/perl/5.10
  - /usr/share/perl/5.10
  - /usr/local/lib/site_perl
  - .
+ tainting @INC is the same without ./

Unlike the deskpro /usr/bin/perl, this one includes a full set of DBI
modules.

** Running Otter Server directly from a Git clone
This can be done, but is potentially fragile

 ln -s $EO/modules        $WEBDIR/lib/otter/74
 ln -s $EO/scripts/apache $WEBDIR/cgi-bin/otter/74

The differences between this and an install with `otterlace_build --server-only` are
+ includes GUI-only modules not in the Bio:: namespace
+ doesn't contain Bio::Otter::Git::Cache
  - this absence can cause taint failures
  - since 3020f3f1 it shouldn't break at compile time

It works, but what happens when the checkout branch jumps to a new
version and the symlink becomes stale?

** Containerised web apps
+ We do not expect to be able to use virtual hosts in this setting.
+ We do not want per-application edits to the main httpd.conf file.

Lacking (knowledge of) a standard scheme for putting multiple
applications on a server in a self-contained way, we push the
responsibility for configuring url:file mappings onto the webapp.

Apps are expected to
+ be a directory ${WEBDIR}/apps/$APPNAME/ (most likely a git working copy)
+ supply Apache config in apps/$APPNAME.conf
  - this should be derived from the template config
    "apps/$APPNAME/app.conf", process to be defined
+ accept the namespace given to them as $APPNAME, possibly with some interpretation
+ apps whose files all reside externally can be added by dropping one
  file, not derived from a template.  The index.conf does this.
** Caveats
*** Use of non-Sanger domains, including localhost
Note that the Otter Client writes the WTSISignOn cookie from enigma
with a .sanger.ac.uk domain, so it will not be used if you are
connecting to localhost.

(If you need to do that, making a duplicate cookie to offer to
localhost should work.)

Symptoms are repeatedly asking for the password, getting 200 OK each
time.
** Open questions
*** DONE Do we want host-dependent environment setup?
As in "source APACHECTL.$(hostname -s).sh"
or something more generalised for a class of machines,
possibly also providing the notion of dev/live

See commits eadc4d27 ("wrapper script config for webteam standard
VMs", adding www-dev.sh) and 13d197ce (rename to setup/www-dev.sh)

The recipe matches that used by the webteam, e.g. for detecting run in
/www/www-live
*** DONE trigger DEVEL mode
This is done by supplying WEBDEFS=DEVEL
either from the calling environment directly
or via a shell fragment at setup/APACHECTL.sh - which should exist
only on developers' branches, e.g.  mca/deskpro .
*** DONE How do we get HTTP_CLIENTREALM set?                        :webteam:
It is passed down from the ZXTM front end proxy, as the
Clientrealm: HTTP header.

SangerWeb.pm (& related) expect it, and it is used (only by testing
for qr/sanger/) in parts of ensembl-otter.

On developers' apache configs, for now, HTTP_CLIENTREALM can be set by
including "lib/devstubs" on OTTER_PERL_INC.  See commit 312b916f .

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
