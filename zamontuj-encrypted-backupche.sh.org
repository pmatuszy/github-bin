#!/bin/bash
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

zpool export zfs_encrypted_file 2>/dev/null
zpool import -d /encrypted.zfs -l -a

zpool status -v

zfs mount zfs_encrypted_file/encrypted

df -h /encrypted

# cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa luks-on-lv
# mount -o noatime /dev/mapper/luks-on-lv /mnt/luks-raid1

echo
echo
echo '########## /dev/vg_crypto/lv_do_luksa_16tb ==> /mnt/luks-raid1-16tb'
echo
echo
cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb luks16tb-on-lv

echo
echo time for fsck ...
echo echo

fsck /dev/mapper/luks16tb-on-lv

echo
echo ... and once again fsck
echo
echo
fsck /dev/mapper/luks16tb-on-lv

mount -o noatime /dev/mapper/luks16tb-on-lv /mnt/luks-raid1-16tb

mount -o bind,noatime /mnt/luks-raid1-16tb/backup1/rclone_user/_restic /rclone-jail/storage-master/backup1
mount -o bind,noatime /mnt/luks-raid1-16tb/replication1/rclone_user/_rclone/ /rclone-jail/storage-master/replication1

df -h /mnt/luks-raid1 /mnt/luks-raid1-16tb

exportfs -a

echo
echo
echo '########## /dev/vg_crypto/lv_do_luksa_16tb_another ==> /mnt/luks-raid1-16tb_another'
echo
echo
cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb_another luks16tb-on-lv_another

echo
echo time for fsck ...
echo echo

fsck /dev/mapper/luks16tb-on-lv_another

echo
echo ... and once again fsck
echo
echo
fsck /dev/mapper/luks16tb-on-lv_another

mount -o noatime /dev/mapper/luks16tb-on-lv_another /mnt/luks-raid1-16tb_another

# mount -o bind,noatime /mnt/luks-raid1-16tb/backup1/rclone_user/_restic /rclone-jail/storage-master/backup1


