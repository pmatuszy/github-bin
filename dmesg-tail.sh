#!/bin/bash
# 2022.12.02 - v. 0.3 - added printing of script version and sleep is now 1.5s
# 2020.11.25 - v. 0.2 - added figlet
# 2020.11.11 - v. 0.1 - initial release

echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

figlet -w 120 kernel logs
sleep 1.5s

dmesg -wT --color=never

