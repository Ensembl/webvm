# Copyright [2020-2021] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# not yet a shellscript, just a collection of oneliners

git grep -hE '\<(use|require)\>.*;' scripts/apache | perl -pe 's/^[ #]*//; if(m{^(?:use|require)\s+(\S+)\s*(?:;|qw|\x22|\x27|\x28|-?\w+\s*=>)}) { $_="$1\n" } else { $_="" }' | sort -u > deps.txt
# nothing is currently required from those scripts which is not
# covered by "require all the modules in ensembl-otter"


curl_otter 'http://web-ottersand-01.internal.sanger.ac.uk:8002/cgi-bin/otter/73/test?more=1&load=1' | perl -MYAML=LoadFile -E '
 my %h=%{ LoadFile(\*STDIN) };
 my $inc=$h{Perl}{q{%INC}};
 $inc =~ s{^\s*(\S+) *(.*)$}{$2\t$1}mg;
 $inc =~ s{\(undef\)}{fail}g;
# $inc =~ s{^(\S*?)/(\S+)\t\g2$}{"$1/\t".f2m($2)}mge;
# $inc =~ s{^((\S*?)/auto/\S+)\t\g1$}{$2/\t$1}mg;
 print $inc;
 while (my ($m, $e) = each %{ $h{load_modules}{error} }) {
   next if $e =~ m{^(Attempt to reload \S+ aborted\.|You cannot augment)}; # Moose
   if ($e =~ s{^(Can.t locate \S+) in .INC.*}{$1}s) {
     print "deps!\t$e\tfor $m\n";
   } else {
     $e =~ s{^}{  }mg;
     print "fail\t$m\t$e\n";
   }
 }
 sub f2m {
  my ($f) = @_;
  $f =~ s{/}{::}g;
  $f =~ s{\.pm$}{};
  return $f;
 }' | sort | less
