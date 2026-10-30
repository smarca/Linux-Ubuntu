#!/bin/bash
cd /tmp
wget https://check.torproject.org/exit-addresses
cat /root/exit-addresses | grep "ExitAddress" | cut -f2 -d " " | gawk -F "." '{ print $1"."$2"."$3".0/24"; }' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq > /etc/firewall/lst/blk_proxy-tor.ini

