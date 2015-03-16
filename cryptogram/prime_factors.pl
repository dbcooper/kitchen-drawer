#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

# IIRC this should be >= sqrt($factor) in order to work
my $MAX_NUM = 5000;

# Number to factor
my $factor = shift() || 1709023;

# prime sieve
my @bit_fields;                         # prime sieve bit field results
for (my $i = 0; $i < $MAX_NUM; $i++) { $bit_fields[$i] = 1; }
for (my $i = 2; $i < $MAX_NUM; $i++) {
    if ($bit_fields[$i]) {
        for (my $j = $i+$i; $j < $MAX_NUM; $j += $i) { $bit_fields[$j] = 0; }
    }
}

# generate list of prime numbers
my @primes;
for (my $i = 2; $i < $MAX_NUM; $i++) { 
    push(@primes, $i) if ($bit_fields[$i]);
}

# I assume we wouldn't find more than one pair of prime number factors but I can't think right now :\
my $found = 0;

my $fl_idx_max = $#primes-1;               # first loop index maximum
for (my $i = 0; $i < $fl_idx_max; $i++) {
    my $a = $primes[$i];
    for (my $j = $i+1; $j < $#primes; $j++) {
        my $b = $primes[$j];
        my $prod = $a*$b;
        if ($prod == $factor) { 
            print "Prime factors of $factor are $a and $b.\n";
            $found++;
        }
    }
}
print "No prime factors found for $factor\n" unless ($found);
