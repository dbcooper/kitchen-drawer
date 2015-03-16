#!/usr/bin/env perl

# Apply a keyword in attempt to reverse a Vigenère cipher

use strict;
use warnings;

use File::Slurp;
use Data::Dumper;

usage() if ($#ARGV <= 0); 

my $keyword = shift(@ARGV);
$keyword = normalize($keyword);

for my $fn (@ARGV) {
    my $cipher = read_file($fn);
    $cipher = normalize($cipher);
    print "Ciphertext:  $cipher\n"; 
    # Make sure key string is long enough for cipher
    my $mult = int( length($cipher) / length($keyword) ) + 1;
    my $key_str = $keyword x $mult;
    print "Keyword:     $key_str\n";
    my @c = char2idx($cipher);
    my @k = char2idx($key_str);
    my @p;
    for my $i ( 0 .. scalar(@c)-1 ) {
        # Have to subtract b/c key was added to cleartext
        my $idx = ($c[$i] - $k[$i]) % 26;
        push @p, $idx;
    }
    my $plain = idx2char(@p);
    print "Plaintext:   $plain\n";
}

# Normalize character sequence
sub normalize
{
    my ($s) = @_;

    $s =~ s/[^a-zA-Z]+//g;
    return lc($s);
}

# Convert a normalized scalar character sequence into a list of indices into English alphabet
sub char2idx
{
    my ($s) = @_;

    my @chars = split //, $s;
    my $zero = ord('a');
    my @indices = map { ord($_) - $zero; } @chars;
    return @indices;
}

# Reverse of char2idx
sub idx2char
{
    my $zero = ord('a');
    my @chars = map { chr($_ + $zero); } @_;
    return join '', @chars;
}

sub usage
{
    warn "Usage: $0 <keyword> <cipher_file>\n";
    exit;
}

