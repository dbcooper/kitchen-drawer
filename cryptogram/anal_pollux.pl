#!/usr/bin/env perl

# Analyze a [simple] Pollux ciphertext

use strict;
use warnings;
use v5.10;

use Algorithm::Combinatorics qw(combinations_with_repetition);
use Data::Dumper;

# The maximum number of [cipher] digits between dividers is 4 for
# alphabetical, 5 for alphanumeric and 6 w/ punctuation symbols.
my $MAX_BETWEEN = 5;


my @set = qw( 0 1 2 3 4 5 6 7 8 9 );
# TODO  Remove elements from set (first and last digit aren't dividers?)
my @combinations = combinations_with_repetition(\@set, 3);

# A digit repeated three times is not a valid divider
my @invalid = qw(000 111 222 333 444 555 666 777 888 999);

my $num2comb = { };     # map digit to all possible (unique) combinations that contain that digit
my $last_pos = { };     # last pos() for any digit in triplet
my $max_dist = { };     # maximum distance between any pair of digits in triplet

for my $lref (@combinations) {
    my $combo = join '', sort @{$lref};
    # TODO  Throw out anything in @invalid?
    $last_pos->{$combo} = -1;
    $max_dist->{$combo}  = 0;
    # Since combinations can have repeated digits, use a hash to track occurance
    for my $n (@{$lref}) {
        $num2comb->{$n}->{$combo}++;
    }
}
# Replace hash with combinations for keys with sorted list
for my $k (keys %{$num2comb}) {
    my @combos = sort keys %{$num2comb->{$k}};
    $num2comb->{$k} = [ @combos ];
}

# Track maximum distance between the occurance of any digit w/in a triplet
my $pos = 0;                            # number of digits processed
my $cipher = '';                        # ciphertext message
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    s/\s+//g;
    die "?invalid characters in $_\n" if m/[^0-9]+/;
    $cipher .= $_;
    for my $d (split //) {
        # Update stats for all triplets containing digit $d
        for my $trip ( @{$num2comb->{$d}} ) {
            my $last = $last_pos->{$trip};
            unless ($last == -1) {
                my $dist = $pos - $last;
                $max_dist->{$trip} = $dist if ($max_dist->{$trip} < $dist) ;
            }
            $last_pos->{$trip} = $pos;
        }
        $pos++;
    }
}


# Distance includes endpoint.  Number of [cipher] digits between is $dist-1
#
# The maximum number of [cipher] digits between dividers is 4 for alphabetical,
# 5 for alphanumeric and 6 w/ punctuation symbols.
#
# Any sets with distances greater than 5, 6, or 7 are not valid dividers
#
# Assumes a dividers cannot occur in sequences longer than two (word separator)

my @dist_order = sort { $max_dist->{$a} <=> $max_dist->{$b}; } keys %{$max_dist};

my %t2b;
for my $trip (@dist_order) {
    my $between = $max_dist->{$trip} - 1;
    last if $between > $MAX_BETWEEN;
    my $set = join ' ', split //, $trip;
    if ($between <= 0) {
        warn "?throwing out $set because it did not appear in ciphertext\n";
        next;
    }
    if ( my ($sequence) = ( $cipher =~ m/([$trip]{3,})/ ) ) {
        warn "?throwing out $set due to repeated sequence $sequence\n";
        next;
    }
    $t2b{$set} = $between;
}

print <<EOL

Based on a maximum of $MAX_BETWEEN digits between each divider, here are valid triplets of dividers:

            Digits
Triplet     Between
-------     -------
EOL
    ;
for my $k (sort keys %t2b) {
    printf " %s       $t2b{$k}\n", $k;
}
