#!/bin/bash

# 2021.09.19 - v. 0.5 - zmiana w fsck, dodana funkcja zrob_fsck
# 2021.08.29 - v. 0.4 - exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu
# 2021.04.09 - v. 0.3 - bug fix: nie montowane byly backup2 i replication2 w jailu...
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# zpool export zfs_encrypted_file 2>/dev/null
# zpool import -d /encrypted.zfs -l -a

# zpool status -v

# zfs mount zfs_encrypted_file/encrypted

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

echo
echo '########## /dev/vg_crypto/lv_do_luksa_16tb ==> /mnt/luks-raid1-16tb'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb luks16tb-on-lv -d -

zrob_fsck /dev/mapper/luks16tb-on-lv

echo
echo '########## /dev/vg_crypto/lv_do_luksa_16tb_another ==> /mnt/luks-raid1-16tb_another'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb_another luks16tb-on-lv_another -d -

zrob_fsck /dev/mapper/luks16tb-on-lv_another


mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

mount -o noatime /dev/mapper/luks16tb-on-lv /mnt/luks-raid1-16tb
mount -o noatime /dev/mapper/luks16tb-on-lv_another /mnt/luks-raid1-16tb_another

mount -o bind,noatime /mnt/luks-raid1-16tb/backup1/rclone_user/_restic /rclone-jail/storage-master/backup1
mount -o bind,noatime /mnt/luks-raid1-16tb/replication1/rclone_user/_rclone/ /rclone-jail/storage-master/replication1

mount -o bind,noatime /mnt/luks-raid1-16tb_another/backup2/rclone_user/_restic /rclone-jail/storage-master/backup2
mount -o bind,noatime /mnt/luks-raid1-16tb_another/replication2/rclone_user/_rclone/ /rclone-jail/storage-master/replication2

df -h /encrypted /mnt/luks-raid1 /mnt/luks-raid1-16tb 

exportfs -a

sleep 2 

nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication1-rclone:/server/MASTER_SOURCE-BBC /mnt/minidlna/MASTER_SOURCE-BBC &
sleep 3
nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication1-rclone:/server/MASTER_SOURCE-SkyPlus /mnt/minidlna/MASTER_SOURCE-SkyPlus &
sleep 3
nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication2-rclone:/server/DivX /mnt/minidlna/DivX &
sleep 3

# odczekamy dodatkowe 15s bo rclone mount troche trwa
sleep 15

service minidlna restart

echo rescan minidlna
sudo -u minidlna /usr/sbin/minidlnad -r
sleep 2 

