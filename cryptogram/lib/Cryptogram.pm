package Cryptogram;

# Library for routines used across multiple scripts in Cryptogram

use v5.10;
use strict;
use warnings;

use File::Slurp;
use Tree::Trie;

my $DEBUG = 0;

# Algorithm does better with a simpler set of words
#my $DICTIONARY = '/usr/share/dict/words';
my $DICTIONARY = 'words.txt';           # default dictionary
my $trie;                               # dictionary data structure


# Initialize dictionary struct from filename, returns Trie handle
sub _dictionary_init
{
    my ($fn) = @_;

    warn "?dictionary structure already exists?!" if ($trie);
    $trie = new Tree::Trie;
    my @words = map { lc($_); } read_file( $fn, chomp => 1 );
    my $nwords = scalar @words;
    my $t0 = time();
    $trie->add(@words);
    my $delta = time() - $t0;
    warn "?added $nwords words to trie in $delta seconds\n" if ($DEBUG);
    return $trie;
}

# Separate words in $input, returns altered version
sub separate_words
{
    my ($input) = @_;

    $input = lc $input;
    my $pos = 0;                        # position w/in searched
    my $spaced;                         # input w/ spaces added
    my $max = length($input);

POSITION:
    while ($pos < $max) {
        my $word = find_longest_word($input, $pos, $max-$pos);
        unless ($word) {
            $pos++;
            next POSITION;
        }
        my $len = length($word);
        warn qq(?found $len character word "$word" at position $pos\n) if ($DEBUG);
        $pos += $len;
        $spaced .= "$word ";
    }

    return $spaced;
}

# Try to find longest word (maximum $max_len letters long) starting at position $pos in string $str
sub find_longest_word
{
    my ($str, $pos, $max_len) = @_;

    unless ($trie) {
        $trie = _dictionary_init($DICTIONARY);
    }

    my $len = 3;                        # starting guess
    $max_len = 32 unless ($max_len);    # dichlorodiphenyltrichloroethane
    $len = $max_len if ($len > $max_len);
    my $llm = 0;                        # length of last match
    my $no_match;                       # flag, prevent infinite loop
SUBSTRING:
    while ($len > 0) {
        my $ss = substr $str, $pos, $len;
        my @matches = $trie->lookup($ss);
        unless (@matches) {
            warn qq(?no matches for "$ss" (length $len) at position $pos, looking for a smaller word\n) if ($DEBUG);
            if ($llm) {
                $len = $llm;
            }
            else {
                $len--;
            }
            $no_match = 1;
            next SUBSTRING;
        }
        if ( @matches == 1 && length($matches[0]) == $len ) {
            return $matches[0];
        }
        if ($llm && $len == $llm) {
            # Second time around?  Settle for word in result set w/ length $llm
            return $ss;
        }
        # If we're here, multiple matches.  KISS
        if ($len < $max_len) {
            for my $m (@matches) {
                # Only set llm if we find a word of exactly that length
                if (length($m) == $len) {
                    $llm = $len;
                    last;
                }
            }
            unless ($no_match) {
                $len++;
                next SUBSTRING;
            }
            # We're unable to match the slightly larger word exactly, so fall through/give up
        }
        # if ($len == $max_len) then substring should be largest word ?
        return $ss;
    }
    return if ($len <= 0);              # no match found
}

1;
