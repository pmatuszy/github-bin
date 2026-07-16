#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.07.15 - v. 0.2 - fix y/Y confirm (was always true); init p for nounset on read timeout
# 2025.10.22 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (vmware-pgm-reinstall).

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

installer_full_path="/vmware/VMware-Workstation-Full-17.6.4-24832109.x86_64.bundle"
installer_full_path="/vmware/VMware-Workstation-Full-25H2-24995812.x86_64.bundle"

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo 
  exit 1
fi

boxes <<< "vmrun list"
vmrun list

export DISPLAY=
echo ; vmware -v ; echo

export wersja=$(vmware -v|awk '{print $3}')

echo "Do you want to reinstall vmware after the kernel update? [y/N]"
p=""
read -t 300 -n 1 p || true     # read one character (-n) with timeout of 300 seconds
echo
if [[ ! "${p}" =~ ^[yY]$ ]]; then
  echo "no means no - I am exiting..."
  exit 1
fi

type -fP "${installer_full_path}" 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find ${installer_full_path} installer... exiting ..."; echo
  exit 1
fi

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo 

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo

boxes <<< "${installer_full_path} --uninstall-product=vmware-workstation --required  --console"
"${installer_full_path}" --uninstall-product=vmware-workstation --required  --console ; echo

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo

boxes <<< "${installer_full_path} --required --eulas-agreed --console"
"${installer_full_path}" --required --eulas-agreed --console ; echo

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo


. /root/bin/_script_footer.sh
