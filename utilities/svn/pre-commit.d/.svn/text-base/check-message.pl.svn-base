#!/usr/bin/perl

## Checks that the message being submitted is valid
##
## Usage          : check-message.pl {repository name} {transaction-id}
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Const::Fast qw(const);

const my $MIN_LENGTH => 12;
const my $MIN_WORDS  => 2;

use Cwd            qw(abs_path);
use English        qw(-no_match_vars $PROGRAM_NAME);
use File::Basename qw(dirname);

my $ROOT_PATH;

BEGIN {
  $ROOT_PATH = dirname(dirname(dirname(dirname(abs_path($PROGRAM_NAME)))));
}

use lib "$ROOT_PATH/lib";

use Pagesmith::Utils::SVN::Support;

exit 1 if @ARGV < 2; # Must have two parameters - repository path and transaction ID

my( $repos, $txn ) = @ARGV;

my $support = Pagesmith::Utils::SVN::Support->new();

# Get information about the transaction, in this case we are only interested in the length
# and the commit message

my( $author, $datestamp, $length, @msg ) = $support->svnlook( 'info', $repos, '-t', $txn );

# Rudimentary count of words in the message

my $words = (my @T = split m{\s+}mxs, join q( ), @msg ); # @T to avoid deprecated warning

exit 0 if $length >= $MIN_LENGTH && $words >= $MIN_WORDS; # Commit can go ahead so we exit with value 0

$support->send_message( sprintf
  "Please use a more meaningful commit message (at least %d characters and %d words)\n\n  '%s'",
    $MIN_LENGTH, $MIN_WORDS,
    join q( ), @msg)->clean_up();

exit 1;  # Commit is cancelled in this case!
