#!/usr/bin/env perl

# Analyze a [simple] Pollux ciphertext

use strict;
use warnings;
use v5.10;

use Algorithm::Combinatorics qw(combinations_with_repetition);
use Data::Dumper;
use Getopt::Std;

# The maximum number of [cipher] digits between dividers is 4 for
# alphabetical, 5 for alphanumeric and 6 w/ punctuation symbols.
my $MAX_BETWEEN = 4;

my $SET_SIZE    = 3;                    # size of divider set {3,4}

our %opts;
getopts('b:s:', \%opts);                # -b between, -s set_size
$MAX_BETWEEN = $opts{b} if (exists $opts{b});
$SET_SIZE    = $opts{s} if (exists $opts{s});

my @set = qw( 0 1 2 3 4 5 6 7 8 9 );
my @combinations = combinations_with_repetition(\@set, $SET_SIZE);

my $num2comb = { };     # map digit to all possible (unique) combinations that contain that digit
my $last_pos = { };     # last pos() for any digit in divider set
my $max_dist = { };     # maximum distance between any pair of digits in divider set

for my $lref (@combinations) {
    my $combo = join '', sort @{$lref};
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

# Track maximum distance between the occurance of any digit w/in a divider set
my $pos = 0;                            # number of digits processed
my $cipher = '';                        # ciphertext message
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    s/\s+//g;
    die "?invalid characters in $_\n" if m/[^0-9]+/;
    $cipher .= $_;
    for my $d (split //) {
        # Update stats for all divider sets containing digit $d
        for my $set ( @{$num2comb->{$d}} ) {
            my $last = $last_pos->{$set};
            unless ($last == -1) {
                my $dist = $pos - $last;
                $max_dist->{$set} = $dist if ($max_dist->{$set} < $dist) ;
            }
            $last_pos->{$set} = $pos;
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
for my $set (@dist_order) {
    my $between = $max_dist->{$set} - 1;
    last if $between > $MAX_BETWEEN;
    my $s = join ' ', split //, $set;
    if ($between <= 0) {
        warn "?throwing out $s because it did not appear in ciphertext\n";
        next;
    }
    if ( my ($sequence) = ( $cipher =~ m/([$set]{3,})/ ) ) {
        warn "?throwing out $s due to repeated sequence $sequence\n";
        next;
    }
    $t2b{$s} = $between;
}

print <<EOL

Based on a maximum of $MAX_BETWEEN digits between each divider set ($SET_SIZE elements),
here are valid divider sets:

  Divider       Digits
  Set           Between
-----------     -------
EOL
    ;
for my $k (sort keys %t2b) {
    printf " %-10s        $t2b{$k}\n", $k;
}

