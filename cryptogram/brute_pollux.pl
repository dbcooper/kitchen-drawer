#!/usr/bin/env perl

# Brute force a [simple] Pollux ciphertext, given divider values

use strict;
use warnings;
use v5.10;

use Algorithm::Combinatorics qw(subsets);
use Data::Dumper;
use Getopt::Std;
use Text::Morse;

use FindBin;
use lib "$FindBin::Bin/lib";
use Cryptogram;

my $dictionary = "$FindBin::Bin/etc/words.txt";
Cryptogram::_dictionary_init($dictionary);


our %opts;
getopts('d:', \%opts);

die "Usage: $0 -d <dividers> <cipher_file>\n" unless $opts{d};

$opts{d} =~ s/[^0-9]+//g;               # only single digits, no separator necessary
my @dividers = split //, $opts{d};
warn "?dividers = { " . join(' ', @dividers) . " }\n";

# Dit and dah set sizes depend on dividers count:
# 4 dividers » sets of (3, 3), 3 dividers » sets of (3, 4)

my @universe = (0..9);
my @remaining = set_difference(\@universe, \@dividers);

my $morse = new Text::Morse;

my $cipher = '';
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    s/\s+//g;
    $cipher .= $_;
}
warn "?cipher is $cipher\n";

die "?invalid characters in ciphertext [^0-9]" if ($cipher =~ m/[^0-9]/);

# ¿ Is alternation (dit and dah) unnecessary if there are 4 elements in the divider set ?!
my @ss = subsets(\@remaining, 3);
for my $lref (@ss) {
    my @diff = set_difference(\@remaining, $lref);

    # Process current subset as dit (dot)
    my $solution = { };
    $solution->{' '}    = \@dividers;
    $solution->{'.'}    = $lref;        # dit
    $solution->{'-'}    = \@diff;       # dah, escaped for tr///
    if (solve($cipher, $solution)) {
        print "# $solution->{key_pp}\n";
        print "# awl=$solution->{awl}\n";
        print "$solution->{clear}\n";
    }

    # Process current subset as dah (dash)
    $solution = { };
    $solution->{' '}    = \@dividers;
    $solution->{'.'}    = \@diff;       # dit
    $solution->{'-'}    = $lref;        # dah
    if (solve($cipher, $solution)) {
        print "# $solution->{key_pp}\n";
        print "# awl=$solution->{awl}\n";
        print "$solution->{clear}\n";
    }
}


# Decode pollux cipher using single map/translation table
sub solve
{
    my ($cipher, $href) = @_;

    my ($from, $to) = build_key($href);
    $href->{from} = $from;
    $href->{to} = $to;
    my $msg = pollux2morse($cipher, $from, $to);
    $href->{morse} = $msg;
    my $clear = $morse->Decode($msg);
    return if ($clear =~ m/scrambled/); # invalid morse code sequence

    # Space string
    my $spaced = Cryptogram::separate_words($clear);
    $href->{clear} = $spaced;
    $href->{awl} = Cryptogram::avg_word_length($spaced);

    # Generate human-readable (pretty print) decoder key
    my %l2k = ('dividers'=>' ', 'dit'=>'.', 'dah'=>'-');
    my @pp_sets;
    while ( my ($label, $key) = each(%l2k) ) {
        push @pp_sets, "$label={ " . join(' ', @{$href->{$key}}) . " };"
    }
    $href->{key_pp} = join '  ', @pp_sets;

    return $href;
}

# Convert pollux cipher text into morse code using tr//
sub pollux2morse
{
    my ($str, $from, $to) = @_;

    # Apparently have to use eval :\
    eval "\$str =~ tr/$from/$to/" or die $@;
    return $str;
}

# Build tr// strings from pollux translation table
sub build_key
{
    my ($href) = @_;

    my @replace;
    for my $sym (keys %{$href}) {
        for my $idx ( @{$href->{$sym}} ) { # set of numbers to map to symbol
            $replace[$idx] = $sym;
        }
    }
    my ($from, $to) = ('', '');
    for my $i (0..9) {
        $from .= $i;
        $to   .= $replace[$i];
    }
    $to =~ s/-/\\-/g;
    return ($from, $to);
}

# Return list of @a - @b (passed via reference)
sub set_difference {
    my ($a_lref, $b_lref) = @_;

    my @result;
    for my $a (@{$a_lref}) {
        next if $a ~~ @{$b_lref};
        push @result, $a;
    }
    return @result;
}
