#! /bin/sh

# Ran in https://rt.sanger.ac.uk/Ticket/Display.html?id=315205#txn-6659499
# (CPAN test deps took too long)

aptitude install -q -q -q -y $( grep -vE '^#' <<EOF

# Otter Server
libb-hooks-endofscope-perl
libbio-perl-perl
libbio-perl-run-perl
libclass-load-perl
libclass-load-xs-perl
libclone-perl
libdata-optlist-perl
libdbd-mysql-perl
libdbi-perl
libdevel-globaldestruction-perl
liberror-perl
libeval-closure-perl
libhttp-cookies-perl
libhttp-date-perl
libhttp-message-perl
liblist-moreutils-perl
liblog-log4perl-perl
libmodule-runtime-perl
libmoose-perl
libmro-compat-perl
libnamespace-autoclean-perl
libnamespace-clean-perl
libpackage-deprecationmanager-perl
libpackage-stash-perl
libpackage-stash-xs-perl
libparams-classify-perl
libparams-util-perl
libreadonly-perl
libreadonly-xs-perl
libsub-exporter-perl
libsub-install-perl
libsub-name-perl
libtry-tiny-perl
liburi-perl
libvariable-magic-perl
libwww-curl-perl
libwww-perl
libxml-libxml-perl
libxml-parser-perl
libxml-sax-base-perl
libxml-simple-perl
libyaml-perl
liblingua-en-inflect-perl

# old SangerWeb dependency, for Otter Server; also in Otter client
libconfig-inifiles-perl

# cubane - for sandbox
libspreadsheet-parseexcel-perl
libspreadsheet-writeexcel-perl

# PipeMon - for sandbox
libswitch-perl
libcatalyst-devel-perl

# pipeline-deps - for sandbox
graphviz

# cgi-bin/otterlist - for sandbox
libfile-slurp-perl

# irc2rss - for sandbox
libdatetime-format-w3cdtf-perl
libirc-utils-perl
libplack-perl
libpoe-component-irc-perl
libxml-rss-perl

# commandline tools
tig

EOF
)

cpan $( grep -vE '^#' <<EOF

# Otter Server
Bio::Das::Lite

# pipeline-deps - for sandbox
GraphViz2

# webvm
Sys::LoadAvg

EOF
)
