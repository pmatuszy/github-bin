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
  fsck.ext4 -f -y $1
else
  # -C: Display the progress, so you know that something is happening.
  # -M: Don't do anything if the partition is mounted
  # -f: Force a check even if the system thinks that it's not needed.
  fsck      -C -M -R -T -y $1
fi

kod_powrotu=$?
echo "kod powrotu z fsck to $kod_powrotu (przebieg 1-szy)"

if (( $kod_powrotu != 0 ));then
  echo
  echo ... and once again fsck
  echo

  if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
    fsck.ext4 -f -y $1
  else
     # -C: Display the progress, so you know that something is happening.
     # -M: Don't do anything if the partition is mounted
     # -f: Force a check even if the system thinks that it's not needed.
    fsck      -C -M -R -T -y $1
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
# zamontuj_fs_MASTER /dev/vg_20230906_skasujto/lv_20230906_skasujto  /mnt/luks-temp  noatime
# zamontuj_fs_MASTER /dev/vg_crypto_20230925/lv_crypto_20230925      /mnt/luks-worek noatime

# zamontuj_fs_MASTER /dev/vg_crypto_20230807/lv_luks_20230807   /mnt/luks-raid1-A  noatime
zamontuj_fs_MASTER /dev/mapper/luks-on-lv_crypto_20231205   /mnt/luks-raid1-A  noatime

# !!! buffalo2 ma SMR dyski, wiec inaczej je montujemy !!!!
zamontuj_fs_MASTER /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2    /mnt/luks-buffalo2  noatime,data=writeback,barrier=0,nobh,errors=remount-ro
dd

echo
df -h /encrypted /mnt/luks-buffalo2 /mnt/luks-raidsonic

echo ; echo
echo "restart nfs servera, bo zwykle jest problem polegajacy na tym, ze service nie startuje od razu, bo nie sa zamontowane exportowane fs'y"
echo "wiec teraz po ich zamontowaniu, restartujemy serwis..."
echo ; echo
systemctl restart nfs-kernel-server

echo
exportfs -av
echo

. /root/bin/_script_footer.sh

