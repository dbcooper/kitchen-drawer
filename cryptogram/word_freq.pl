#!/usr/bin/env perl

# Calculate frequency of word appearance in text

use strict;
use warnings;

use Data::Dumper;

my %words;
my $sum = 0;                            # total number of words
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    for my $w (split /\s+/) {
        $words{lc $w}++;
        $sum++;
    }
}

# Pretty printing calculations
my $freq_max_width = length($sum);
my $max_word_len = 0;
for my $k (keys %words) {
    my $l = length($k);
    $max_word_len = $l if ($l > $max_word_len);
}

# Sort by frequency
my @freq_order = sort { $words{$b} <=> $words{$a} } keys %words;
for my $k (@freq_order) {
    my $freq = $words{$k};
    my $pct = $freq/$sum * 100;
    printf "%${max_word_len}s  %${freq_max_width}d (%8.4f%%)\n", $k, $freq, $pct;
}

