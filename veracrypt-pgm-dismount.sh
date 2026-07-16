#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - v. 0.2 - English messages
# 2026.05.26 - v. 0.1 - initial release: Linux VeraCrypt dismount by mount point

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (veracrypt-pgm-dismount).

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

if [[ "$(uname -s)" != Linux ]]; then
  echo
  echo "(PGM) This script supports Linux only (uname -s=$(uname -s))."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

if [ "$(id -u)" -ne 0 ]; then
  echo
  echo "(PGM) VeraCrypt dismount requires root."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

check_if_installed veracrypt

export VERACRYPT_BIN=$(type -fP veracrypt)
if [ -z "${VERACRYPT_BIN}" ]; then
  echo
  echo "(PGM) I can't find veracrypt utility... exiting ..."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

if (( $# != 1 )); then
  echo
  echo "(PGM) wrong # of command line arguments... (must be exactly 1)"
  echo "$0 mount_directory"
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

export VC_MOUNT="$1"

if [[ ! -d "${VC_MOUNT}" ]]; then
  echo
  echo "(PGM) mount directory does not exist: ${VC_MOUNT}"
  echo "$0 mount_directory"
  echo
  return_code=2
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

if ! mountpoint -q "${VC_MOUNT}"; then
  echo
  echo "(PGM) ${VC_MOUNT} is not a mount point — nothing to dismount."
  echo
  return_code=0
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

echo
echo "(PGM) Dismounting ${VC_MOUNT} ..."
echo

"${VERACRYPT_BIN}" -t --dismount "${VC_MOUNT}"
return_code=$?

if (( return_code != 0 )); then
  echo
  echo "(PGM) veracrypt dismount failed (exit ${return_code})."
  echo
fi

. /root/bin/_script_footer.sh

exit "${return_code}"
