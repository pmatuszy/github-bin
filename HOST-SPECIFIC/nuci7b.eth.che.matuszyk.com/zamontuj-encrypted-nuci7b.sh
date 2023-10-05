#!/bin/bash

# 2023.03.27 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################
echo ; echo "==> ########## zrob_fsck($1)"

echo czas na fsck $1 ...

if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
  fsck.ext4 -f -p $1
else
  fsck      -C -M -R -T $1
fi

kod_powrotu=$?
echo "kod powrotu z fsck to $kod_powrotu (przebieg 1-szy)"

if (( $kod_powrotu != 0 ));then
  echo
  echo ... and once again fsck
  echo

  if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
    fsck.ext4 -f -p $1
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

vgchange -a y
sleep 1

# zamontuj_fs_MASTER /dev/vg_crypto_raidsonic/lv_do_luksa_raidsonic  /mnt/luks-raidsonic noatime

zamontuj_fs_MASTER /dev/vg_20230906_skasujto/lv_20230906_skasujto  /mnt/luks-temp  noatime
zamontuj_fs_MASTER /dev/vg_crypto_20230925/lv_crypto_20230925      /mnt/luks-worek noatime

echo
df -h /encrypted /mnt/luks-temp /mnt/luks-worek

. /root/bin/_script_footer.sh

