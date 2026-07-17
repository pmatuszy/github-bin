#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.01.26 - v. 0.2 - added script version print
# 2022.11.21 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (umount-encrypted-enclosures).

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

################################################################################
odmontuj_fs_MASTER() {
echo ; echo "==> ########## odmontuj_fs_MASTER($1)"

if [ $(mountpoint -q $1 ; echo $?) -ne 0 ] ; then
   echo $1 NIE is already mounted ... exiting
   echo "<== ########## odmontuj_fs_MASTER($1)"
   return 
fi

luks_device="$(df -h $1 | grep $1  | awk '{print $1}')"

umount $1 

if (( $? != 0 ));then
  echo  ; echo "CANNOT UNMOUNT $1 !!!!!!!"; echo "exiting ..."
  echo "<== ########## odmontuj_fs_MASTER($1)"
  umount -l $1
  sleep 5
else
  echo "dismount zrobiony"
fi

sleep 1 

echo cryptsetup luksClose ${luks_device}
cryptsetup luksClose ${luks_device}

if (( $? != 0 ));then
  echo  ; echo "CANNOT CLOSE LUKS DEVICE $1 !!!!!!!"; echo "exiting ..."
  echo "<== ########## odmontuj_fs_MASTER($1)"
  return
else
  echo "luksClose zrobiony"
fi

echo "<== ########## odmontuj_fs_MASTER($1)"
}
################################################################################

odmontuj_fs_MASTER /mnt/luks-dyskD
odmontuj_fs_MASTER /mnt/luks-buffalo1
