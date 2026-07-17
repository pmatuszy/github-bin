#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.04.04 - v. 1.0 - bugfix with fsck (instead of hardcoded /dev/mapper/encrypted_luks_device_encrypted.luks2 will use $1)
# 2023.01.26 - v  0.9 - added . /root/bin/_script_footer.sh as it was not there..., fixed script version print
# 2023.01.13 - v  0.8 - a nicer display of the mount command status
# 2022.12.02 - v  0.7 - bugfix with fsck return code
# 2022.11.24 - v  0.6 - added restart of postgress and keepalived
# 2022.11.21 - v  0.5 - a lot of changes - too many to describe here :-)
# 2022.11.20 - v  0.4 - added vgchange -a y
# 2022.11.20 - v  0.3 - added mounting dyskD
# 2022.11.20 - v  0.3 - added mounting dyskD
# 2022.10.11 - v  0.2 - added healthcheck support 
# 2022.07.30 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

disabled - present but not mounted (USB cable removed from hub)

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

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

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

mount_fs_master /encrypted.luks2                                /encrypted           noatime

echo "restart of keepalived service ..."
systemctl restart keepalived

echo "restart of postgresql service ..."
systemctl restart postgresql

# disabled - present but not mounted (USB cable removed from hub
######## mount_fs_master /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1               /mnt/luks-buffalo1   noatime

mount_fs_master /dev/vg_crypto_20221208_RaidSonicA/lv_20221208_RaidSonicA  /mnt/luks-RaidSonicA noatime
mount_fs_master /dev/vg_crypto_20221209_RaidSonicB/lv_20221209_RaidSonicB  /mnt/luks-RaidSonicB noatime

# mount_fs_master /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD          /mnt/luks-dyskD      noatime,data=writeback,barrier=0,nobh,errors=remount-ro

echo
df -h /encrypted /mnt/luks-buffalo1 /mnt/luks-RaidSonicA /mnt/luks-RaidSonicB

/root/bin/healthchecks-encrypted-is-mounted.sh

. /root/bin/_script_footer.sh
