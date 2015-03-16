#!/usr/bin/perl 

use strict;
use warnings;

# monoalpha.pl  Apply monoalphabetic solution mapping to file(s)
# Author: Niall Durham, niall.durham@gmail.com
# Last modified: 09 June 2005

use Getopt::Std;

our %opts;
getopts('o', \%opts);

usage($0) if ($#ARGV <= 0); 

# Input solution mapping.
my $mapfile = shift(@ARGV);
my %cipher2key;
open my $fh, '<', $mapfile || die "Unable to open file $mapfile: $!";
while (<$fh>) {
    next if (m/^\s*#/ || m/^\s*$/); 
    chomp();
    $_ = lc();
    my ($cipher, $key) = split(/[:\s]+/);
    $cipher2key{$cipher} = $key;
}
close($fh);

# Read in msg. file(s)
my $msg;
while (my $file = shift(@ARGV)) {
    open my $fh, '<', $file || die "Unable to open $file: $!";
    # slurp in file contents
    {
        local $/;
        $msg .= <$fh>;
    }
    close($fh);
}
$msg = uc($msg);

# Translate message using mapping.
my $searchlist  = uc(join('', keys(%cipher2key)));
my $replacelist = join('', values(%cipher2key));
my $trans = $msg;
eval "\$trans =~ tr/$searchlist/$replacelist/";
print "Original:\n$msg\nTranslated:\n" if ($opts{o});
print "$trans\n";

exit 0;


sub usage
{
    my ($arg0) = @_;

    print "$arg0: <mapfile> <file1> [<file2> <file3> ...]\n";
    exit 0;
}

