#!/bin/bash
# 2020.11.01 - v. 0.5 - remove zfs_usb reference
# 2020.10.21 - v. 0.4 - added comment about import with rewind
# 2020.10.13 - v. 0.3 - exporting all zpools and then importing them
# 2020.10.09 - v. 0.2 - small cosmetic changes
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# DO NOT TRY IT IN PRODUCTION. USE AT YOUR OWN RISK!
# zpool import -FX mypool where options mean:
# * -F Attempt rewind if necessary.
# * -X Turn on extreme rewind.
# * -T Specify a starting txg to use for import. This option is intentionally undocumented option for testing purposes.

jd.sh

echo "nacisnij <ENTER>"
read r

dmesg -T

echo "nacisnij <ENTER>"
read r

set +x
#zpool export zfs_usb   2>/dev/null
zpool export zfs-raid1 2>/dev/null

zpool import -d /dev/disk/by-id -l -a

set -x

zpool status -v

zfs mount -a

df -h

zfs set sharenfs="rw=@192.168.200.138/32,rw=@192.168.200.109/32,no_root_squash" zfs-raid1/podsync-hdd

mount -o bind /mnt/zfs-raid1/replication1/rclone_user /rclone-jail/storage-master/replication1
mount -o bind /mnt/zfs-raid1/backup1/rclone_user /rclone-jail/storage-master/backup1
