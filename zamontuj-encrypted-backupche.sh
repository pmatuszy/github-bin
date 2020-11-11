#!/bin/bash
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

zpool export zfs_encrypted_file 2>/dev/null
zpool import -d /encrypted.zfs -l -a

zpool status -v

zfs mount zfs_encrypted_file/encrypted

df -h /encrypted

cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa luks-on-lv
mount -o noatime /dev/mapper/luks-on-lv /mnt/luks-raid1

df -h /mnt/luks-raid1

exportfs -a