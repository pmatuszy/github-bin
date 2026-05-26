#!/bin/bash

# 2026.05.26 - v. 0.1 - initial release: Linux VeraCrypt dismount by mount point

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
  echo "(PGM) VeraCrypt dismount requires root."
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

if (( $# != 1 )); then
  echo
  echo "(PGM) wrong # of command line arguments... (must be exactly 1)"
  echo "$0 mount_directory"
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

export VC_MOUNT="$1"

if [[ ! -d "${VC_MOUNT}" ]]; then
  echo
  echo "(PGM) mount directory does not exist: ${VC_MOUNT}"
  echo "$0 mount_directory"
  echo
  kod_powrotu=2
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

if ! mountpoint -q "${VC_MOUNT}"; then
  echo
  echo "(PGM) ${VC_MOUNT} is not a mount point — nothing to dismount."
  echo
  kod_powrotu=0
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

echo
echo "(PGM) Dismounting ${VC_MOUNT} ..."
echo

"${VERACRYPT_BIN}" -t --dismount "${VC_MOUNT}"
kod_powrotu=$?

if (( kod_powrotu != 0 )); then
  echo
  echo "(PGM) veracrypt dismount failed (exit ${kod_powrotu})."
  echo
fi

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
