#!/bin/bash
# 2020.12.08 - v. 0.2 - adding info about total RAM
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# tr -d '\0'` below is to get rid of the message "warning: command substitution: ignored null byte in input"

echo
echo `cat /proc/device-tree/model|tr -d '\0'` ",   " `cat /proc/meminfo |grep MemTotal|awk '{printf ("Total RAM: %.0f GB", $2/1024/1024)}'`
echo

