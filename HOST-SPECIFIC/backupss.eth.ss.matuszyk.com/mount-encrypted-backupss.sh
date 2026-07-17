#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2025.11.04 - v. 0.1 - changed -y to -p in fsck.ext4
# 2023.03.27 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

-C: Display the progress, so you know that something is happening.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) break ;;
  esac
done

echo
read -r -p "Enter password: " -s PASSWD
echo

################################################################################
run_fsck() {
################################################################################
echo ; echo "==> ########## run_fsck($1)"

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
echo "<== ########## run_fsck($1)"
}
################################################################################
mount_fs_master() {
echo ; echo "==> ########## mount_fs_master($1, $2, $3)"

if [ $(mountpoint -q $2 ; echo $?) -eq 0 ] ; then
   echo $1 is already mounted ... exiting
   echo "<== ########## mount_fs_master($1, $2, $3)"
   return
fi

echo -n "$PASSWD" | cryptsetup luksOpen "${1}" encrypted_luks_device_"$(basename ${1})" -d -

if (( $? != 0 ));then
  echo  ; echo "CANNOT MOUNT $1 at $2 !!!!!!!"; echo "exiting ..."
  echo "<== ########## mount_fs_master($1, $2, $3)"
  return
fi

run_fsck /dev/mapper/encrypted_luks_device_"$(basename ${1})"
mount -o $3 /dev/mapper/encrypted_luks_device_"$(basename ${1})" "${2}"

if (( $? == 0 ));then
  echo ; echo "mount of $1 under $2 was SUCCESSFUL" ; echo
fi

echo "<== ########## mount_fs_master($1, $2, $3)"
}
################################################################################

vgchange -a y
sleep 1

mount_fs_master /encrypted.luks2                         /encrypted            noatime
mount_fs_master /dev/vg_crypto_encA/lv_do_luksa_encA     /mnt/luks-raid1-encA  noatime
mount_fs_master /dev/vg_crypto_encB/lv_do_luksa_encB     /mnt/luks-raid1-encB  noatime

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
/root/bin/healthchecks-vpn-server-is-running.sh
/root/bin/healthchecks-smartd.sh

. /root/bin/_script_footer.sh
