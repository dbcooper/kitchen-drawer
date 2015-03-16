#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $n = 0;
my %freq;

while (my $x = shift(@ARGV)) {
    my @l = factors($x);
    print "Factors for $x: @l\n";
    foreach my $f (@l) { $freq{$f}++; }
    $n++;
}
print "\nCommon factors: ";
foreach my $k ( sort { $a <=> $b } keys %freq ) {
    # should never be >, but just to be on the safe side
    if ($freq{$k} >= $n) { print "$k "; }
}
print "\n";

# return a list w/ the factors for $x
sub factors
{
    my ($x) = @_;
    my ($quot, @l);

    for (my $i = 1; $i <= $x; $i++) {
        $quot = $x/$i;
        push(@l, $i) if ($quot == int($quot)); 
    }
    return @l;
}

