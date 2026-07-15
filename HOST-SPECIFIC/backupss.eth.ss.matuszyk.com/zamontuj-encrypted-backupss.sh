#!/bin/bash

# 2026.05.26 - user-facing messages translated from Polish to English
# 2025.11.04 - v. 0.1 - changed -y to -p in fsck.ext4
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
  # -C: Display the progress, so you know that something is happening.
  # -M: Don't do anything if the partition is mounted
  # -f: Force a check even if the system thinks that it's not needed.
  fsck      -C -M -R -T -y $1
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
     # -C: Display the progress, so you know that something is happening.
     # -M: Don't do anything if the partition is mounted
     # -f: Force a check even if the system thinks that it's not needed.
    fsck      -C -M -R -T -y $1
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

zamontuj_fs_MASTER /encrypted.luks2                         /encrypted            noatime
zamontuj_fs_MASTER /dev/vg_crypto_encA/lv_do_luksa_encA     /mnt/luks-raid1-encA  noatime
zamontuj_fs_MASTER /dev/vg_crypto_encB/lv_do_luksa_encB     /mnt/luks-raid1-encB  noatime

sleep 1

mount -o bind,noatime /mnt/luks-raid1-encA/replication/rclone-user/_rclone /rclone-jail/storage-master/replicationA
mount -o bind,noatime /mnt/luks-raid1-encB/replication/rclone-user/_rclone /rclone-jail/storage-master/replicationB
mount -o bind,noatime /mnt/luks-raid1-encA/backup/rclone-user/_restic      /rclone-jail/storage-master/backupA
mount -o bind,noatime /mnt/luks-raid1-encB/backup/rclone-user/_restic      /rclone-jail/storage-master/backupB

echo
df -h /encrypted /mnt/luks-raid1-encA /mnt/luks-raid1-encB \
      /rclone-jail/storage-master/replicationA /rclone-jail/storage-master/replicationB \
      /rclone-jail/storage-master/backupA /rclone-jail/storage-master/backupB

echo ; echo startuje vpnserver ; echo
/encrypted/vpnserver/vpnserver start
/root/bin/sprawdz-czy-dziala-server-vpn.sh
/root/bin/healthchecks-smartd.sh

. /root/bin/_script_footer.sh
