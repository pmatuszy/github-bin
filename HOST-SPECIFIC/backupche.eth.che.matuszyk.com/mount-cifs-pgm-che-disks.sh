#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay
# 2022.02.20 - v. 0.3 - renamed host and added mkdir -p
# 2021.04.09 - v. 0.2 - changed IP to machine DNS name 
# 2020.0x.xx - v. 0.1 - initial release (date unknown)


show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (mount-cifs-pgm-che-disks).

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
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

set +x

echo
echo
echo  pgm-che
echo
echo

mkdir -p /mnt/pgm-che/DyskC /mnt/pgm-che/DyskD /mnt/pgm-che/DyskE /mnt/pgm-che/DyskF

read -p "Enter password: " -s PASSWD ; echo


loc_dir_name="/mnt/pgm-che/DyskC"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskC"
umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

loc_dir_name="/mnt/pgm-che/DyskD"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskD"
umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

loc_dir_name="/mnt/pgm-che/DyskE"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskE"
umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

df -hP |egrep 'Filesystem|pgm-che.eth.che.matuszyk.com'

set +x

. /root/bin/_script_footer.sh
