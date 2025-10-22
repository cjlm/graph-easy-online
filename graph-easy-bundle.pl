#!/usr/bin/env perl
# This script bundles Graph::Easy and provides a simple interface

use strict;
use warnings;

# First, load all Graph::Easy modules into the filesystem
BEGIN {
    # We'll inline the module code here
    print STDERR "Loading Graph::Easy modules into virtual filesystem...\n";
}

# For now, just test that we can create a simple function
sub convert_graph {
    my ($input) = @_;

    # This is a placeholder - will load Graph::Easy properly
    return "Graph conversion not yet implemented\nInput was: $input";
}

# Export to JavaScript
use WebPerl qw/js/;

# Make the function available to JavaScript
js('window')->{convertGraphPerl} = sub {
    my ($input) = @_;
    return convert_graph($input);
};

print STDERR "Graph::Easy bundle loaded and ready!\n";

1;
