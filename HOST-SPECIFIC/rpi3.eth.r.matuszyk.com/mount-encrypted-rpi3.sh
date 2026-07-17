#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2022.10.19 - v. 0.3 - added sprawdzenie czy dziala server vpn
# 2022.09.30 - v. 0.2 - added wsparcie dla healthcheckow
# 2021.09.06 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (mount-encrypted-rpi3).

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

luks_file_path=/encrypted.luks2
cryptsetup luksOpen ${luks_file_path} encrypted_luks_file_in_root
mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

df -h /encrypted

echo startuje vpnserver

/encrypted/vpnserver/vpnserver start

/root/bin/healthchecks-encrypted-is-mounted.sh
/root/bin/healthchecks-vpn-server-is-running.sh

. /root/bin/_script_footer.sh
