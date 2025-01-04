#!/bin/bash

#Count lines in NetshieldIP.txt
rows=$(wc -l /usr/local/bin/Netshield/NetshieldIP.txt |awk '{print $1}')
#Spawn sub process, one proces for each core on thw system
seq 0 $rows | parallel --progress --delay 2 /usr/local/bin/Netshield/Influx_Netshield.sh
exit
