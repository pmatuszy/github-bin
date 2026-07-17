#!/bin/bash
# v. 20260717.220000 - rename zamontuj-encrypted.sh -> mount-encrypted.sh
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.02.28 - v. 0.5 - curl with return_code
# 2022.07.01 - v. 0.4 - added call to /root/bin/healthchecks-encrypted-is-mounted.sh at the end
# 2022.06.21 - v. 0.3 - added healthchecks support
# 2021.09.19 - v. 0.2 - added fsck function and password read into variable
# 2021.01.30 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (mount-encrypted).

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo
read -r -p "Enter password: " -s PASSWD
echo

################################################################################
run_fsck() {
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

luks_file_path=/encrypted.luks2

echo -n "$PASSWD" | cryptsetup luksOpen ${luks_file_path} encrypted_luks_file_in_root -d -
run_fsck /dev/mapper/encrypted_luks_file_in_root

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted
return_code=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

df -h /encrypted
echo

/root/bin/healthchecks-encrypted-is-mounted.sh

. /root/bin/_script_footer.sh
exit ${return_code}
