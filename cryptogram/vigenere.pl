#!/usr/bin/perl 

use strict;
use warnings;

# vigenere.pl  Apply vigenere solution to split files
# Author: Niall Durham, niall.durham@gmail.com
# Last modified: 09 June 2005

my $ALPHABET = 'abcdefghijklmnopqrstuvwxyz';

usage($0) if ($#ARGV < 0); 

# Input solution mapping.
my $mapfile = shift(@ARGV);
my @href_list;                          # some kind of file/index/cipher/plaintext structure
open my $fh, '<', $mapfile || die "Unable to open file $mapfile: $!";
while (<$fh>) {
    next if (m/^\s*#/ || m/^\s*$/); 
    chomp();
    my ($key, $file) = split(/[:\s]+/);
    my $idx;
    if ($key =~ m/^\d+$/) {
        $idx = int($key);               # numeric index for keyword letter
    } 
    elsif ($key =~ m/^\D+$/) {          # convert alpha to numeric index
        $idx = rindex($ALPHABET, $key) % 26;
    }
    my $href = { 'file' => $file, 'idx' => $idx };
    push(@href_list, $href);
}
close($fh);

# Read in each cyphertext file.
my $msg_len = 0;
foreach my $m (@href_list) {
    my $file = $m->{file};
    open my $fh, '<', $file || die "Unable to open $file: $!";
    my $txt;
    # slurp in file contents
    {
        local $/;
        $txt = <$fh>;
    }
    close($fh);
    $txt =~ s/\s+//;
    $m->{cipher} = uc($txt);
    $msg_len += length($txt);
}

# Translate each section of the message using appropriate shift of 
# alphabet.
my $replacelist = $ALPHABET;
foreach my $m (@href_list) {
    my $idx = $m->{idx};
    my $cipher = $m->{cipher};
    my $searchlist = uc(substr($ALPHABET, $idx) . substr($ALPHABET, 0, $idx));
    eval "\$cipher =~ tr/$searchlist/$replacelist/";
    $m->{plain} = $cipher;
}

# Join the separate messages together.
my $msg;                                # plaintext message?
my $cnt = $#href_list + 1;
for (my $i = 0; $i < $msg_len; $i++) {
    my $m = $href_list[$i % $cnt];
    my $c = substr($m->{plain}, int($i/$cnt), 1);
    $msg .= $c;
}

print "$msg\n";

exit 0;


sub usage
{
    my ($arg0) = @_;

    print "$arg0: <mapfile>\n";
    exit 0;
}

