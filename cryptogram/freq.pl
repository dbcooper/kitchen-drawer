#!/usr/bin/perl 

use strict;
use warnings;

# freq.pl  Frequency analysis tool

use Getopt::Std;
use Text::Graph;
use Text::Graph::DataSet;

our %opts;
getopts('acgl:msw:', \%opts);

my $msg;
# Slurp in input
{
    local $/; 
    $msg = <>;
}

# Pre-process message.
$msg = uc($msg);
$msg =~ s/\s+//g;
$msg =~ s/\W//g if ($opts{a});            # alphanumeric only
print "# Message is ", length($msg), " characters long\n";

my $width = ($opts{w}) ? $opts{w} : 1;
my $limit = ($opts{l}) ? $opts{l} : 1;

my %fa = freq_analysis(\$msg, $width);
# Figure total # of w-sized elements in set.
my $maxlen = 0;                            # max length of frequency string
my $total;
foreach my $k (keys %fa) { 
    my $val = $fa{$k};
    my $strlen = length($val);
    $maxlen = $strlen if ($strlen > $maxlen);
    $total += $val;
} 

# Sort hash keys for output.
my @keylist;
if ($opts{s}) {                           # output by frequency of occurance
    @keylist = sort { $fa{$b} <=> $fa{$a} } keys %fa;
} else {                                # alphabetical output
    @keylist = sort keys %fa;
}

if ($opts{m}) {
    # Output blank mapfile
    print "# blank mapfile generated by freq.pl\n";
    foreach my $k (@keylist) {
        print "$k: " . uc($k) . "\n";
    }
} else {
    my $value_lref = [ ];
    my $label_lref = [ ];
    foreach my $k (@keylist) {
        my $freq = $fa{$k};
        my $pct = $freq/$total * 100;
        if ($fa{$k} >= $limit) {
            if ($opts{c}) {             # CSV output
                print "\"$k\",$pct\n";
            } elsif ($opts{g}) {        # prepare graph output
                push @{$label_lref}, $k;
                push @{$value_lref}, $freq;
            } else {
                printf("$k: %${maxlen}d (%8.4f%%)\n", $freq, $pct);
            }
        }
    }
    if ($opts{g}) {                     # output graph
        my $dataset = Text::Graph::DataSet->new($value_lref, $label_lref);
        my $graph = Text::Graph->new( 'Line', showval => 1, fill => '*' );
        print $graph->to_string($dataset);
    }
}


# return hash w/ count of occurance for each substring of length $len.
sub freq_analysis
{
    my ($strref, $len) = @_;
    my (%count, $segment);

    my $str = ${$strref};
    my $last = length($str) - $len;
    for (my $i = 0; $i < $last; $i++) {
        $segment = substr($str, $i, $len);
        $count{$segment}++;
    }
    return %count;
}

