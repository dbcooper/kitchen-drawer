#!/usr/bin/env perl

# Find [some] words buried in a string w/o whitespace
#
# It doesn't have to find /all/ the words, but it should be able to
# detect multiple, valid english words.  I.e., separate gibberish
# from a valid sentence

use v5.10;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Cryptogram;

my $dictionary = "$FindBin::Bin/etc/words.txt";
Cryptogram::_dictionary_init($dictionary);

my $input;                              # total input string
while (<>) {
    next if /^\s*#/ or /^\s*$/;
    chomp();
    $input .= lc $_;
    s/\s+//g;
}

print Cryptogram::separate_words($input) . "\n";

