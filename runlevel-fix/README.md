Fix runlevel links in /etc/rc?.d folders
========================================

I made the mistake of running insserv on an Ubuntu 12.04 box to try
and complete a custom service install

insserv not only tried to install the service I requested but also
(w/o warning or instruction) decided to renumber *all* my installed
services, destroying the finer-grained startup/shutdown order they
originally had.

This is my attempt to repair the damage using "good" service symlink
lists from other Ubuntu 12.04 machines.

See https://bugs.launchpad.net/ubuntu/+source/insserv/+bug/811675

Example
-------

To check my system:

    ./runlevel-fix.pl ubuntu1-dump.txt ubuntu2-dump.txt

If I like what I see, I can tell it to fix the links/services (run as sudo):

    ./runlevel-fix.pl -f ubuntu1-dump.txt ubuntu2-dump.txt

