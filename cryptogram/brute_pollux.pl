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

# Global variables
my $morse = new Text::Morse;


our %opts;
getopts('a:b:d:', \%opts);  # -a minimum_awl, -b num_dividers, -d dividers
usage() unless ( $opts{d} or $opts{b} );

my $cipher = '';
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    s/\s+//g;
    $cipher .= $_;
}
warn "?cipher is $cipher\n";

die "?invalid characters in ciphertext [^0-9]" if ($cipher =~ m/[^0-9]/);

my @dividers_ss;                        # dividers subsets
my @universe = (0..9);
# if opts{b}, generate subsets of universe w/ size $opts{b} else, one
# subset, consisting of @dividers
if ($opts{b}) {
    die "?invalid number of dividers ($opts{b}), should be [3,4]" if ($opts{b} < 3 or $opts{b} > 4);
    @dividers_ss = subsets(\@universe, $opts{b});
}
else {
    $opts{d} =~ s/[^0-9]+//g;           # only single digits, no separator necessary
    my @dividers = split //, $opts{d};
    my $count = scalar @dividers;
    die "?invalid number of dividers ($count), should be [3,4]" if ($count < 3 or $count > 4);
    @dividers_ss = ( [ @dividers ] );
}

# Loop over sets of dividers, further partitioning the remaining
# numbers to brute force ciphertext
for my $dref (@dividers_ss) {
    my @divs = @{$dref};
    my @solutions = brute_dit_dah(@divs);

    for my $href (@solutions) {
        next if ($opts{a} and $href->{awl} < $opts{a});
        print "# $href->{key_pp}\n";
        print "# awl=$href->{awl}\n";
        print "$href->{clear}\n";
    }
}


# Brute force dit and dah given a set of dividers.  Returns list of
# hash references (solution information)
sub brute_dit_dah {
    my (@divs) = @_;
    my @solutions;                      # set of potentially valid solutions

    # Dit and dah set sizes depend on dividers count:
    # 4 dividers » sets of (3, 3), 3 dividers » sets of (3, 4)
    my $subset_size = 3;
    $subset_size = 4 if (scalar(@divs) == 3) ;

    my @remaining = set_difference(\@universe, \@divs);
    my @ss = subsets(\@remaining, $subset_size);

    # ¿ Is alternation (dit and dah) unnecessary if there are 4 elements in the divider set ?!
    my %seen_ss;                        # track seen subsets
SUBSET:
    for my $lref (@ss) {
        my @diff = set_difference(\@remaining, $lref);
        my $key = join ' ', @{$lref};
        if ( $seen_ss{$key} ) {
            warn "?already seen subset $key, skipping\n";
        }
        $seen_ss{$key}++;

        # Process current subset as dit (dot)
        my $solution = build_solution(\@divs, $lref, \@diff);
        if (solve($cipher, $solution)) {
            push @solutions, $solution;
        }

        # Process current subset as dah (dash)
        $solution = build_solution(\@divs, \@diff, $lref);
        if (solve($cipher, $solution)) {
            push @solutions, $solution;
        }
    }
    return @solutions;
}


sub build_solution
{
    my ($div_lref, $dit_lref, $dah_lref) = @_;

    my $solution = { };
    $solution->{' '}    = $div_lref;
    $solution->{'.'}    = $dit_lref;    # dit
    $solution->{'-'}    = $dah_lref;    # dah
    return $solution;
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

sub usage
{
    warn <<EOL
Usage:  $0 [-a <awl>] -d <dividers> <cipher_file>
        $0 [-a <awl>] -b <number_dividers> <cipher_file>
EOL
    ;
    exit 0;
}
