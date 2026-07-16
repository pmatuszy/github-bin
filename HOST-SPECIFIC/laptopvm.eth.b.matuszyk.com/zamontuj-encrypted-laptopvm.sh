#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2021.09.19 - v. 0.5 - zmiana w fsck, dodana funkcja zrob_fsck
# 2021.08.29 - v. 0.4 - exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu
# 2021.04.09 - v. 0.3 - bug fix: nie montowane byly backup2 i replication2 w jailu...
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (zamontuj-encrypted-laptopvm).

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

echo "################################################################################"
echo
echo running fsck on $1 ...
echo
echo "################################################################################"

fsck -C -M -R -T -V $1

echo
echo ... and once again fsck
echo
fsck $1
}
################################################################################

echo
echo '########## /dev/vg_crypto/lv_do_luksa_16tb ==> /mnt/luks-raid1-16tb'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_buffalo3/lv_do_luksa_buffalo3 luks_buffalo3 -d -

zrob_fsck /dev/vg_crypto_buffalo3/lv_do_luksa_buffalo3

mount -o noatime /dev/mapper/luks_buffalo3 /mnt/luks_buffalo3

df -h /mnt/luks_buffalo3

