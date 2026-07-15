#!/bin/bash

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.03.27 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo
read -r -p "Enter password: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################
echo ; echo "==> ########## zrob_fsck($1)"

echo running fsck on $1 ...

if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
  fsck.ext4 -f -p $1
else
  fsck      -C -M -R -T $1
fi

return_code=$?
echo "fsck exit code: $return_code (pass 1)"

if (( $return_code != 0 ));then
  echo
  echo ... and once again fsck
  echo

  if [ $(lsblk -no FSTYPE $1) == 'ext4' ];then
    fsck.ext4 -f -p $1
  else
    fsck      -C -M -R -T $1
  fi
  echo "fsck exit code: $? (pass 2)"
else
  echo "fsck completed"
fi
echo "<== ########## zrob_fsck($1)"
}
################################################################################
zamontuj_fs_MASTER() {
echo ; echo "==> ########## zamontuj_fs_MASTER($1, $2, $3)"

if [ $(mountpoint -q $2 ; echo $?) -eq 0 ] ; then
   echo $1 is already mounted ... exiting
   echo "<== ########## zamontuj_fs_MASTER($1, $2, $3)"
   return
fi

echo -n "$PASSWD" | cryptsetup luksOpen "${1}" encrypted_luks_device_"$(basename ${1})" -d -

if (( $? != 0 ));then
  echo  ; echo "CANNOT MOUNT $1 at $2 !!!!!!!"; echo "exiting ..."
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
zamontuj_fs_MASTER /dev/vg_crypto_20231205/lv_crypto_20231205   /mnt/luks-raid1-A  noatime

# !!! buffalo2 ma SMR dyski, wiec inaczej je montujemy !!!!
zamontuj_fs_MASTER /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2 /mnt/luks-buffalo2 noatime,data=writeback,barrier=0,nobh,errors=remount-ro

# /mnt/luks-NO-MIRROR SMR !!!!!!
# zamontuj_fs_MASTER /dev/vg_crypto_20240714_NO-MIRRROR/lv_crypto_20240714_NO-MIRRROR /mnt/luks-NO-MIRROR noatime,data=writeback,barrier=0,nobh,errors=remount-ro

echo
df -h /encrypted /mnt/luks-buffalo2 /mnt/luks-raidsonic

echo ; echo
echo "restarting NFS server (service often fails at boot because exported filesystems are not mounted yet)"
echo "now that they are mounted, restarting the service..."
echo ; echo
systemctl restart nfs-kernel-server

echo
exportfs -av
echo

. /root/bin/_script_footer.sh

