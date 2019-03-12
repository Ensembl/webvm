=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package WebVM::GitLatest;
use strict;
use warnings;

use LWP::UserAgent;
use XML::XPath;
use XML::XPath::XMLParser;


sub new {
    my ($pkg) = @_;
    my $self = { _ua => undef };
    bless $self, $pkg;
    return $self;
}

sub ua {
    my ($self) = @_;
    return $self->{_ua} ||= do {
        my $ua = LWP::UserAgent->new;
        $ua->agent("$0 ");
        $ua->timeout(10);
        $ua->env_proxy;
        $ua;
    };
}


# Ask our gitweb server, return list of --abbrev=8 commitids
sub latest_ciid {
    my ($self, $dir, $ref, $abbr) = @_;
    my $url = "http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=$dir;a=atom;h=$ref";

    my $resp = $self->ua->get($url);
    if ($resp->is_success) {
        my $xp = XML::XPath->new(xml => $resp->decoded_content);
        my $nodeset = $xp->find('/feed/entry/id');
        my @ciid;
        foreach my $node ($nodeset->get_nodelist) {
            my $id = XML::XPath::XMLParser::as_string($node);
            # <id>http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/webvm.git;a=commitdiff;h=f29b84f6a71b9631066d3764995d0b6c5d00fd93</id>
            my ($ciid) = $id =~ m{h=([0-9a-f]{40})}
              or die "Cannot extract ciid from $id";
            push @ciid, substr($ciid, 0, $abbr);
        }
        if (!@ciid) {
            warn "Fetch of $url returned valid atom XML but no commitid\n".
              $resp->decoded_content;
        }
        return @ciid;
    } else {
        die "Fetch of $url failed: ".$resp->status_line;
    }
}


# If the commit we have is not the latest, then are we ahead or
# behind?
sub diagnose {
    my ($pkg, $got_ci, @latest_ci) = @_;

    return 'Absent' unless defined $got_ci;

    my $n = @latest_ci - 1;
    my ($found_idx) = grep { $got_ci eq $latest_ci[$_] } (0..$n);

    if (!defined $found_idx) {
        return "Ahead or >$n commits behind";
    } elsif (0 == $found_idx) {
        return 'Up-to-date';
    } else {
        return "$found_idx commit(s) behind";
    }
}



1;
