#!/usr/bin/perl

# Compare init.d script links on current machine to those from a
# "known good" system and update current machine's to match the known
# good settings.  Doesn't modify files unless given the -f option
#
# "Known good" system dump must be supplied by the user.  There should
# be several in this repo from Ubuntu 12.04 machines.  Use at your own
# risk.
#
# You can build a "known good" system dump by capturing the output of:
#
#     /usr/bin/find /etc/rc*
#

use strict;
use warnings;
use feature 'state';

use Data::Dumper;
use File::Basename;
use Getopt::Std;

# Constants
my $INIT_D_PATH = '/etc/init.d';

# "Globals"
my %svc_map;  # "authoritative" map of services, and runlevel-specific action and orders
my %opts;

getopts('if', \%opts);
die "?Usage [-if] $0 <service_dump_file_1> ...\n" unless (@ARGV);

for my $fn (@ARGV) {
    open my $fh, '<', $fn or die "?unable to open $fn for reading: $!";
    my @lines = <$fh>; # slurp
    warn "?parsing $fn to build service map\n";
    walk_service_dump(\&add_service, @lines);
    close $fh;
}

# Do a simple check to see what services in /etc/init.d aren't covered
# by the service map
#
# Just because entries are in /etc/init.d doesn't mean they *should*
# have entries in /etc/rc?.d directories
#
if ($opts{i}) {
    my @services = get_installed();
    for my $s (@services) {
        warn "?entry not found for service $s in service map\n" unless (exists $svc_map{$s});
    }
}

my $local_services = `/usr/bin/find /etc/rc*`;
walk_service_dump( \&fix_service_entry, split(/\n/, $local_services) );


# Do appropriate thing w/ map of services from a dump like `/bin/ls -1 /etc/rc*`
sub walk_service_dump
{
    my ($coderef, @lines) = @_;

    my $path;                               # current path/service directory
    my $runlevel;                           # current runlevel (directory)
    for (@lines) {
        chomp();
        next if /^\s*$/ || /readme$/i;      # stuff to ignore
        next if /rc.local$/;                # script, not directory
        next if /^\s*#/;                    # comment

        my ($p, $r, $a, $o, $s);            # variables for conditional scope
        my $rv = 0;                         # return value
        if ( ($p, $r) = m#^(/etc/rc(.+)\.d):\s*$#  ) { # runlevel
            $path = $p;
            $runlevel = $r;
        }
        elsif ( ($a, $o, $s) = m/^(K|S)(\d+)(.*)$/ ) {
            $rv = &$coderef($runlevel, $a, $o, $s);
        }
        elsif ( ($r, $a, $o, $s) = m#rc([^.]+)\.d/(K|S)(\d+)(.*)$# ) {
            unless ($r eq $runlevel) {
                warn "?Runlevel from path «$r» doesn't match current runlevel «$runlevel», using $r?\n";
                $runlevel = $r;
            }
            $rv = &$coderef($r, $a, $o, $s);
        }
        elsif (  my ($r) = ( m#/rc([^.]+)\.d$# )  ) { # Files listed w/ find ?
            $runlevel = $r;
        }
        else {
            warn "?don't know what to do with line «$_»\n";
        }
        if ($rv and $rv < 0) {
            warn "?error when processing line «$_»\n";
            $rv = 0;
        }
    }
}

# Add an entry for a service at a particular runlevel to the service map
sub add_service
{
    my ($runlevel, $action, $order, $service) = @_;

    my $lref = [ $action, $order ];
    if (exists $svc_map{$service}) {
        my $s_href = $svc_map{$service};
        unless (exists $s_href->{$runlevel}) {
            $s_href->{$runlevel} = $lref;
        }
        else {
            my ($a, $o) = @{ $s_href->{$runlevel} };
            unless ($action eq $a and $order eq $o) {
                warn "?existing $service service entry (action=$a, order=$o) for runlevel $runlevel doesn't match new one (action=$action, order=$order)\n";
                return -1;
            }
        }
    }
    else {
        $svc_map{$service} = { $runlevel => $lref };
    }
}

# Fix local service entry to match ones in service map
sub fix_service_entry
{
    my ($runlevel, $action, $order, $service) = @_;
    state %warned;

    if (not exists $svc_map{$service} and not $warned{$service}) {
        warn "?entry not found for service $service in service map, ignoring future occurances\n";
        $warned{$service}++;
        return -1;
    }
    return if ($warned{$service});
    unless (exists $svc_map{$service}->{$runlevel}) {
        warn "?no entry for service $service at runlevel $runlevel in service map, skipping\n";
        return -1;
    }

    my ($a, $o) = @{ $svc_map{$service}->{$runlevel} };
    my $path = "/etc/rc$runlevel.d";
    my $src = "$path/$action$order$service";
    my $dest = "$path/$a$o$service";

    die "?source service file $src doesn't exist (wrong path?)" unless (-e $src);
    die "?source service file $src isn't a symlink?" unless (-l $src);

    return if ($src eq $dest);          # nothing to do
    if ($opts{f}) {
        die "?file $src isn't writeable by uid $>" unless (-w $src);
        # Rename source file to dest
        die "?error when renaming $src to $dest: $!" unless (rename $src, $dest);
    }
    else {
        warn "?should rename $src to $dest, use -f option to fix issue(s)\n";
    }
}

# Return installed (non upstart) services
sub get_installed
{
    my @fqdn_services = glob "$INIT_D_PATH/*";
    my @raw_services;
    for my $f (@fqdn_services) {        # ignore upstart entries
        unless (-l $f and readlink($f) eq '/lib/init/upstart-job') {
            push @raw_services, basename $f;
        }
    }
    my @services = grep(!/^(?:rc.*|README|skeleton)/, @raw_services); # filter non-services

    return @services;
}

