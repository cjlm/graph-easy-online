use strict;
use warnings;
use lib "$ENV{HOME}/perl5/lib/perl5";
use Graph::Easy;

my $input = 'graph { A -- B; A -- B; A -- C; A -- C; A -- D; B -- D; C -- D }';

my $graph = Graph::Easy->new($input);
if ($graph->error()) {
  die "Error: " . $graph->error();
}
print $graph->as_ascii();
