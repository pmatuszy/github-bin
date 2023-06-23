#!/bin/bash

# 2023.05.11 - v. 0.6 - wylaczenie startowania uslugi VPN
# 2021.09.19 - v. 0.5 - zmiana sciezki do vpnservera, zmieny w fsck, dodana funkcja zrob_fsck
# 2021.02.18 - v. 0.4 - bugfix - added /encrypted at the end of mount -o noatime command
# 2021.02.03 - v. 0.3 - replace zfs with luks2 /encrypted directory
# 2021.01.06 - v. 0.2 - added additional bind mountpoints
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# zpool export zfs_encrypted_file 2>/dev/null
# zpool import -d /encrypted.zfs -l -a

# zpool status -v

# zfs mount zfs_encrypted_file/encrypted
# zfs mount zfs_encrypted_file

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################

echo "################################################################################"

echo
echo czas na fsck $1 ...
echo 
echo "################################################################################"

fsck -C -M -R -T -V $1

echo
echo ... and once again fsck
echo
fsck $1
}
################################################################################

nazwa_pliku=/encrypted.luks2

echo -n "$PASSWD" | cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root -d -
zrob_fsck /dev/mapper/encrypted_luks_file_in_root

echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_encA/lv_do_luksa_encA luks-on-lv_encA -d -
zrob_fsck /dev/mapper/luks-on-lv_encA

echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_encB/lv_do_luksa_encB luks-on-lv_encB -d -
zrob_fsck /dev/mapper/luks-on-lv_encB

################################################################################

echo "################################################################################"

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted
mount -o noatime /dev/mapper/luks-on-lv_encA /mnt/luks-raid1-encA
mount -o noatime /dev/mapper/luks-on-lv_encB /mnt/luks-raid1-encB

mount -o bind,noatime /mnt/luks-raid1-encA/replication/rclone-user/_rclone /rclone-jail/storage-master/replicationA
mount -o bind,noatime /mnt/luks-raid1-encB/replication/rclone-user/_rclone /rclone-jail/storage-master/replicationB
mount -o bind,noatime /mnt/luks-raid1-encA/backup/rclone-user/_restic      /rclone-jail/storage-master/backupA
mount -o bind,noatime /mnt/luks-raid1-encB/backup/rclone-user/_restic      /rclone-jail/storage-master/backupB

df -h /encrypted
echo
df -h /mnt/luks-raid1-encA /mnt/luks-raid1-encB
echo
df -h /rclone-jail/storage-master/backupA /rclone-jail/storage-master/replicationA
echo
df -h /rclone-jail/storage-master/backupB /rclone-jail/storage-master/replicationB
echo

echo startuje vpnserver

/encrypted/vpnserver/vpnserver start

/root/bin/sprawdz-czy-dziala-server-vpn.sh
