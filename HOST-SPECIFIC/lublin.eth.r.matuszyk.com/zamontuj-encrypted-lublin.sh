#!/bin/bash
# 2022.12.02 - v  0.7 - bugfix with fsck return code
# 2022.11.24 - v  0.6 - added restart of postgress and keepalived
# 2022.11.21 - v  0.5 - a lot of changes - too many to describe here :-)
# 2022.11.20 - v  0.4 - added vgchange -a y
# 2022.11.20 - v  0.3 - added mounting dyskD
# 2022.11.20 - v  0.3 - added mounting dyskD
# 2022.10.11 - v  0.2 - added healthcheck support 
# 2022.07.30 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

cat  $0|grep -e '2022'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################
echo ; echo "==> ########## zrob_fsck($1)"

echo czas na fsck $1 ...

if [ $(lsblk -no FSTYPE /dev/mapper/encrypted_luks_device_encrypted.luks2) == 'ext4' ];then
  fsck.ext4 -f $1
else
  fsck      -C -M -R -T $1
fi

kod_powrotu=$?
echo "kod powrotu z fsck to $kod_powrotu (przebieg 1-szy)"

if (( $kod_powrotu != 0 ));then
  echo
  echo ... and once again fsck
  echo

  if [ $(lsblk -no FSTYPE /dev/mapper/encrypted_luks_device_encrypted.luks2) == 'ext4' ];then
    fsck.ext4 -f $1
  else
    fsck      -C -M -R -T $1
  fi
  echo "kod powrotu z fsck to $? (przebieg 2-gi)"
else
  echo "fsck zrobiony"
fi
echo "<== ########## zrob_fsck($1)"
}
################################################################################
zamontuj_fs_MASTER() {
echo ; echo "==> ########## zamontuj_fs_MASTER($1, $2, $3)"

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
}
################################################################################

vgchange -a y
sleep 1

zamontuj_fs_MASTER /encrypted.luks2                                /encrypted           noatime

systemctl restart keepalived
systemctl restart postgresql

zamontuj_fs_MASTER /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1    /mnt/luks-buffalo1   noatime
# zamontuj_fs_MASTER /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD /mnt/luks-dyskD      noatime,data=writeback,barrier=0,nobh,errors=remount-ro
zamontuj_fs_MASTER /dev/mapper/luks-on-lv_20221208_RaidSonicA      /mnt/luks-RaidSonicA noatime
zamontuj_fs_MASTER /dev/mapper/luks-on-lv_20221209_RaidSonicB      /mnt/luks-RaidSonicB noatime

echo
df -h /encrypted /mnt/luks-buffalo1 /mnt/luks-RaidSonicA /mnt/luks-RaidSonicB

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
