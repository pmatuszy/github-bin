#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - v. 0.3 - English password prompt and messages
# 2026.05.26 - v. 0.2 - interactive password; fixed --pim=0 --keyfiles= --protect-hidden=no
# 2026.05.26 - v. 0.1 - initial release: Linux VeraCrypt mount via CLI (volume + mount point)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (veracrypt-pgm-mount).

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
  echo "(PGM) VeraCrypt mount requires root."
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

if (( $# != 2 )); then
  echo
  echo "(PGM) wrong # of command line arguments... (must be exactly 2)"
  echo "$0 volume_path mount_directory"
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

export VC_VOLUME="$1"
export VC_MOUNT="$2"

if [[ ! -e "${VC_VOLUME}" ]]; then
  echo
  echo "(PGM) volume not found: ${VC_VOLUME}"
  echo "$0 volume_path mount_directory"
  echo
  return_code=2
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

mkdir -p "${VC_MOUNT}"

if mountpoint -q "${VC_MOUNT}"; then
  echo
  echo "(PGM) ${VC_MOUNT} is already a mount point — skipping mount."
  echo
  df -hP "${VC_MOUNT}"
  echo
  return_code=0
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

echo
read -r -p "Enter password: " -s PASSWD
echo
echo
echo "(PGM) Mounting ${VC_VOLUME} -> ${VC_MOUNT} ..."
echo

echo -n "${PASSWD}" | "${VERACRYPT_BIN}" -t --mount "${VC_VOLUME}" "${VC_MOUNT}" \
  --pim=0 --keyfiles= --protect-hidden=no
return_code=$?
unset PASSWD

if (( return_code == 0 )); then
  echo
  df -hP "${VC_MOUNT}"
  echo
else
  echo
  echo "(PGM) veracrypt mount failed (exit ${return_code})."
  echo
fi

. /root/bin/_script_footer.sh

exit "${return_code}"
