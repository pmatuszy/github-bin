#!/bin/bash

# 2026.05.26 - v. 0.3 - English password prompt and messages
# 2026.05.26 - v. 0.2 - interactive password; fixed --pim=0 --keyfiles= --protect-hidden=no
# 2026.05.26 - v. 0.1 - initial release: Linux VeraCrypt mount via CLI (volume + mount point)

. /root/bin/_script_header.sh

if [[ "$(uname -s)" != Linux ]]; then
  echo
  echo "(PGM) This script supports Linux only (uname -s=$(uname -s))."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

if [ "$(id -u)" -ne 0 ]; then
  echo
  echo "(PGM) VeraCrypt mount requires root."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

check_if_installed veracrypt

export VERACRYPT_BIN=$(type -fP veracrypt)
if [ -z "${VERACRYPT_BIN}" ]; then
  echo
  echo "(PGM) I can't find veracrypt utility... exiting ..."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

if (( $# != 2 )); then
  echo
  echo "(PGM) wrong # of command line arguments... (must be exactly 2)"
  echo "$0 volume_path mount_directory"
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

export VC_VOLUME="$1"
export VC_MOUNT="$2"

if [[ ! -e "${VC_VOLUME}" ]]; then
  echo
  echo "(PGM) volume not found: ${VC_VOLUME}"
  echo "$0 volume_path mount_directory"
  echo
  kod_powrotu=2
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

mkdir -p "${VC_MOUNT}"

if mountpoint -q "${VC_MOUNT}"; then
  echo
  echo "(PGM) ${VC_MOUNT} is already a mount point — skipping mount."
  echo
  df -hP "${VC_MOUNT}"
  echo
  kod_powrotu=0
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

echo
read -r -p "Enter password: " -s PASSWD
echo
echo
echo "(PGM) Mounting ${VC_VOLUME} -> ${VC_MOUNT} ..."
echo

echo -n "${PASSWD}" | "${VERACRYPT_BIN}" -t --mount "${VC_VOLUME}" "${VC_MOUNT}" \
  --pim=0 --keyfiles= --protect-hidden=no
kod_powrotu=$?
unset PASSWD

if (( kod_powrotu == 0 )); then
  echo
  df -hP "${VC_MOUNT}"
  echo
else
  echo
  echo "(PGM) veracrypt mount failed (exit ${kod_powrotu})."
  echo
fi

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
