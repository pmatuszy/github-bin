#!/bin/bash
# 2020.10.09 - v. 0.2 - small cosmetic changes
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

jd.sh

echo "nacisnij <ENTER>"
read r

dmesg

echo "nacisnij <ENTER>"
read r

set +x
zpool export zfs-raid1-encosureA 2>/dev/null
zpool export zfs-raid1-encosureB 2>/dev/null
zpool import -d /dev/disk/by-id -l -a
zpool status -v

zfs mount -a

df -h

mount -o bind /mnt/replication1/skasujto /rclone-jail/storage-master/
