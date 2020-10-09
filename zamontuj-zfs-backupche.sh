#!/bin/bash
# 2020.10.09 - v. 0.2 - small cosmetic changes
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

jd.sh

echo "nacisnij <ENTER>"
read r

dmesg

echo "nacisnij <ENTER>"
read r

zpool export zfs_usb 2>/dev/null

zpool import -d /dev/disk/by-id -l -a

zpool status -v

zfs mount -a

df -h

zfs set sharenfs="rw=@192.168.200.138/32" zfs_usb/worek/podsync-hdd
