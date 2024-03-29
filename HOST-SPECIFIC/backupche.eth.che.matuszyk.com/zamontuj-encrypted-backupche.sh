#!/bin/bash

# 2023.10.05 - v. 1.1 - added vgchange with 1s delay
# 2023.03.27 - v. 1.0 - bugfix with fsck (instead of hardcoded /dev/mapper/encrypted_luks_device_encrypted.luks2 will use $1)
# 2023.03.20 - v. 0.9 - bugfix with kod_powrotu
# 2023.01.26 - v. 0.8 - added script version print
# 2022.12.01 - v. 0.7 - zmieniona zrob_fsck na nowsza - i wymuszenie fsck -y
# 2022.05.23 - v. 0.6 - dodane wywolanie healthchecka na koncu
# 2021.09.19 - v. 0.5 - zmiana w fsck, dodana funkcja zrob_fsck
# 2021.08.29 - v. 0.4 - exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu
# 2021.04.09 - v. 0.3 - bug fix: nie montowane byly backup2 i replication2 w jailu...
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# zpool export zfs_encrypted_file 2>/dev/null
# zpool import -d /encrypted.zfs -l -a

# zpool status -v

# zfs mount zfs_encrypted_file/encrypted

. /root/bin/_script_header.sh

echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################
echo ; echo "==> ###### zrob_fsck($1)"

echo czas na fsck $1 ...

if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
  fsck.ext4 -f $1
else
  fsck      -C -M -R -T $1
fi

kod_powrotu=$?
echo "kod powrotu z fsck to $kod_powrotu"

if (( $kod_powrotu != 0 ));then
  echo ; echo "... and once again fsck " ; echo

  if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
    fsck.ext4 -f $1
  else
    fsck      -C -M -R -T $1
  fi
  echo "kod powrotu z fsck to $?"
else
  echo "fsck zrobiony"
fi
echo "<== ###### zrob_fsck($1)"
}
################################################################################
zamontuj_fs_MASTER() {
################################################################################
echo ; echo "==> ########## zamontuj_fs_MASTER($1, $2, $3)"
       echo "==> ########## zamontuj_fs_MASTER($1, $2, $3)"
       echo "==> ########## zamontuj_fs_MASTER($1, $2, $3)"

if [ $(mountpoint -q $2 ; echo $?) -eq 0 ] ; then
   echo $1 jest juz zamontowany ... wychodze
   echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
   return
fi

echo -n "$PASSWD" | cryptsetup luksOpen "${1}" encrypted_luks_device_"$(basename ${1})" -d -

if (( $? != 0 ));then
  echo  ; echo "NIE MOGE ZAMONTOWAC $1 pod $2 !!!!!!!"; echo "wychodze ..."
  echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
  return
fi

zrob_fsck /dev/mapper/encrypted_luks_device_"$(basename ${1})"
mount -o $3 /dev/mapper/encrypted_luks_device_"$(basename ${1})" "${2}"

echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
}

################################################################################

#nazwa_pliku=/encrypted.luks2

#echo -n "$PASSWD" | cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root -d -
#zrob_fsck /dev/mapper/encrypted_luks_file_in_root

# echo
# echo '########## /dev/vg_crypto/lv_do_luksa_16tb ==> /mnt/luks-raid1-16tb'
# echo
# echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb luks16tb-on-lv -d -

# zrob_fsck /dev/mapper/luks16tb-on-lv

# echo
# echo '########## /dev/vg_crypto/lv_do_luksa_16tb_another ==> /mnt/luks-raid1-16tb_another'
# echo
# echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto/lv_do_luksa_16tb_another luks16tb-on-lv_another -d -

# zrob_fsck /dev/mapper/luks16tb-on-lv_another

vgchange -a y
sleep 1

zamontuj_fs_MASTER /encrypted.luks2                     	/encrypted 			noatime
zamontuj_fs_MASTER /dev/vg_crypto/lv_do_luksa_16tb      	/mnt/luks-raid1-16tb		noatime
# zamontuj_fs_MASTER /dev/vg_crypto/lv_do_luksa_16tb_another 	/mnt/luks-raid1-16tb_another 	noatime
zamontuj_fs_MASTER /dev/vg_crypto_20230925/lv_crypto_20230925 	/mnt/luks-raid1-16tb_another 	noatime

mount -o bind,noatime /mnt/luks-raid1-16tb/backup1/rclone_user/_restic /rclone-jail/storage-master/backup1
mount -o bind,noatime /mnt/luks-raid1-16tb/replication1/rclone_user/_rclone/ /rclone-jail/storage-master/replication1

mount -o bind,noatime /mnt/luks-raid1-16tb_another/backup2/rclone_user/_restic /rclone-jail/storage-master/backup2
mount -o bind,noatime /mnt/luks-raid1-16tb_another/replication2/rclone_user/_rclone/ /rclone-jail/storage-master/replication2

df -h /encrypted /mnt/luks-raid1-16tb /mnt/luks-raid1-16tb_another

nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication1-rclone:/server/MASTER_SOURCE-BBC /mnt/minidlna/MASTER_SOURCE-BBC &
sleep 3
nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication1-rclone:/server/MASTER_SOURCE-SkyPlus /mnt/minidlna/MASTER_SOURCE-SkyPlus &
sleep 3
nohup rclone --config /root/rclone.conf mount --daemon --allow-other --read-only local-crypt-local-replication2-rclone:/server/DivX /mnt/minidlna/DivX &
sleep 3

# odczekamy dodatkowe 15s bo rclone mount troche trwa
echo ; echo ; echo "odczekamy dodatkowe 15s bo rclone mount troche trwa" ; echo
sleep 15

service minidlna restart

echo rescan minidlna
sudo -u minidlna /usr/sbin/minidlnad -r
sleep 2 

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh

. /root/bin/_script_footer.sh
