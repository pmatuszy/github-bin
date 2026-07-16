#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.07.15 - v. 0.7 - fix dpkg open-vm-tools check (always emptied by >/dev/null)
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.09.06 - v. 0.6 - mount cdrom in r/o mode
# 2023.07.03 - v. 0.5 - force installation of tools from vmware...
# 2023.05.09 - v. 0.4 - added checking if the script is run on the virtual machine
# 2023.03.03 - v. 0.3 - if open-vm-tools is installed we will uninstall it
# 2023.03.03 - v. 0.2 - if cdrom is already mounted under /mnt/tmp we do not remount it again....
# 2023.02.17 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Prefer VMware Tools ISO installer over distro open-vm-tools when the package is present.

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

check_if_installed virt-what
if (( $(virt-what | wc -l) == 0 ));then
  echo ; echo "host is NOT a vm... exiting...";echo
  exit 1
fi

if [ ! -f  /mnt/tmp/vmware-tools-upgrader-64 ];then
  mkdir -p /mnt/tmp
  mount -o ro /dev/cdrom /mnt/tmp || exit 2
fi

# Prefer VMware Tools ISO installer over distro open-vm-tools when the package is present.
if dpkg -s open-vm-tools >/dev/null 2>&1; then
  echo "removing open-vm-tools (prefer VMware tools package)" | boxes -s 50x3 -a c -d ada-box
  echo apt remove -y open-vm-tools | boxes -s 50x3 -a c -d ada-box
  apt remove -y --purge open-vm-tools >/dev/null 2>&1
fi

{
rm /tmp/VMwareTools-* 2>/dev/null
cp -fv /mnt/tmp/VMwareTools-* /tmp
cd /tmp ; tar xzf VMwareTools-*
rm /tmp/VMwareTools-* 2>/dev/null
}

umount /mnt/tmp
cd /tmp/vmware-tools-distrib

if (( $# != 0 )) && [ "${1-xxx}" == "manual" ]; then
  echo ; echo "(PGM) enabling manual mode"
  ./vmware-install.pl 
else
  ./vmware-install.pl --default --force-install # install even if open-vm-tools packages are available for this distribution.
fi

. /root/bin/_script_footer.sh
