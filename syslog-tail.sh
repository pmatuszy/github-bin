#!/bin/bash

# 2023.02.06 - v. 0.1 - initial release

echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

figlet -w 120 "syslog tail -F"
sleep 1.5s

if [ -f /ramdisk/syslog ];then
  tail -F -n 2000 /ramdisk/syslog
else
  tail -F -n 2000 /var/log/syslog
fi

