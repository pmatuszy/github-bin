#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2022.12.14 - v  0.6 - a lot of changes - too many to describe here :-)
# 2021.09.19 - v. 0.5 - zmiana w fsck, dodana funkcja zrob_fsck
# 2021.08.29 - v. 0.4 - exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu
# 2021.04.09 - v. 0.3 - bug fix: nie montowane byly backup2 i replication2 w jailu...
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

icybox zostal zniszczony 07.08.2023

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
zrob_fsck() {
################################################################################
echo ; echo "==> ########## zrob_fsck($1)"

echo running fsck on $1 ...

if [ $(lsblk -no FSTYPE /dev/mapper/encrypted_luks_device_encrypted.luks2) == 'ext4' ];then
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

  if [ $(lsblk -no FSTYPE /dev/mapper/encrypted_luks_device_encrypted.luks2) == 'ext4' ];then
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

zamontuj_fs_MASTER /encrypted.luks2                                /encrypted          noatime

# icybox zostal zniszczony 07.08.2023
# zamontuj_fs_MASTER /dev/vg_crypto_icybox10/lv_luks_icybox10 /mnt/luks-icybox10  noatime

# zamontuj_fs_MASTER /dev/vg_crypto_20230807/lv_luks_20230807   /mnt/luks-raid1-A  noatime

# !!! buffalo2 ma SMR dyski, wiec inaczej je montujemy !!!!
zamontuj_fs_MASTER /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2    /mnt/luks-buffalo2  noatime,data=writeback,barrier=0,nobh,errors=remount-ro

# zamontuj_fs_MASTER /dev/vg_crypto_20241105/lv_crypto_20241105   /mnt/luks-raid1-A  noatime

echo
# df -h /encrypted /mnt/luks-buffalo2 /mnt/luks-raidsonic 
df -h /encrypted 

echo ; echo 
echo "restarting NFS server (service often fails at boot because exported filesystems are not mounted yet)"
echo "now that they are mounted, restarting the service..."
echo ; echo 
systemctl restart nfs-kernel-server

echo 
exportfs -av
echo

/root/bin/healthchecks-encrypted-is-mounted.sh

