-*- org -*-

In Emacs & new to org-mode?  Move to Documentation line and hit TAB
twice.

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
You need root to
  mkdir /www/$USER /www/tmp/$USER

Then you
  cd /www/$USER
  git clone intcvs1:/repos/git/users/mca/webvm.git .

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

