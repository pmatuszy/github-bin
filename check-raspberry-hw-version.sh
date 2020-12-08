#!/bin/bash
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

echo `cat /proc/device-tree/model` ",   " `cat /proc/meminfo |grep MemTotal|awk '{printf ("Total RAM: %.0f GB", $2/1024/1024)}'`
echo

