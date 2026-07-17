#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.03.27 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

mount_fs_master /dev/vg_crypto_raidsonic/lv_do_luksa_raidsonic  /mnt/luks-raidsonic noatime

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

# mount_fs_master /dev/vg_crypto_raidsonic/lv_do_luksa_raidsonic  /mnt/luks-raidsonic noatime
# mount_fs_master /dev/vg_20230906_skasujto/lv_20230906_skasujto  /mnt/luks-temp  noatime
# mount_fs_master /dev/vg_crypto_20230925/lv_crypto_20230925      /mnt/luks-worek noatime

# mount_fs_master /dev/vg_crypto_20230807/lv_luks_20230807   /mnt/luks-raid1-A  noatime
mount_fs_master /dev/vg_crypto_20231205/lv_crypto_20231205   /mnt/luks-raid1-A  noatime

# !!! buffalo2 has SMR disks so we mount them differently !!!!
mount_fs_master /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2 /mnt/luks-buffalo2 noatime,data=writeback,barrier=0,nobh,errors=remount-ro

# /mnt/luks-NO-MIRROR SMR !!!!!!
# mount_fs_master /dev/vg_crypto_20240714_NO-MIRRROR/lv_crypto_20240714_NO-MIRRROR /mnt/luks-NO-MIRROR noatime,data=writeback,barrier=0,nobh,errors=remount-ro

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
