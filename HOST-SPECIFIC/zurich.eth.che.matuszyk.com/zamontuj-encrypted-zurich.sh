#!/bin/bash

# 2023.01.16 - v. 0.4 - enable SMR script, starting vpn just after mouting /encrypted and before other volumes
# 2023.01.05 - v. 0.3 - a lot of changes - too many to describe here :-)
# 2022.06.24 - v. 0.2 - dodano obsluge healthcheckow i grep -v grep 
# 2021.01.30 - v. 0.1 - initial release (date unknown)

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

if (( $? == 0 ));then
  echo ; echo "mount of $1 under $2 was SUCCESSFUL" ; echo
fi

echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
}
################################################################################

zamontuj_fs_MASTER /encrypted.luks2                                /encrypted            noatime

echo ; echo startuje vpnserver
/encrypted/vpnserver/vpnserver start
echo ; echo 
ps -ef |grep vpnserver | grep -v grep
echo ; echo

/root/bin/smr-disks-timeout.sh

input_from_user=""
read -t 300 -n 1 -p "Do you want to mount main encrypted volumes? [Y/n/q]: " input_from_user
echo
if [ "${input_from_user}" == 'q' -o  $"{input_from_user}" == 'Q' -o "${input_from_user}" == 'n' -o  $"{input_from_user}" == 'N' ]; then
  echo "nie to nie.... wychodze"
  exit 1
fi

vgchange -a y
sleep 1

zamontuj_fs_MASTER /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD /mnt/luks-lv-icybox-A noatime,data=writeback,barrier=0,nobh,errors=remount-ro

df -h /encrypted /mnt/luks-lv-icybox-A

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
/root/bin/sprawdz-czy-dziala-server-vpn.sh
