#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2021.02.24 - v. 0.1 - initial release - skrypt from https://github.com/maknesium/disable-hugepages
#    autor wrote this article: 
#      https://www.maknesium.de/disable-hugepages-on-linux-yields-huge-speed-improvements-for-vmware-workstation


###########################################################
# disable huge pages on debian/ubuntu based Linux systems #
###########################################################

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

autor wrote this article:

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

echo "Disabling hugepages..."
echo '0'     | sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
# I tend to let the hugepage support enabled...
#echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

echo "=============== State of hugepages on current system ==============="
echo "Current setting for /sys/kernel/mm/transparent_hugepage/khugepaged/defrag"
cat /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo "Current setting for /sys/kernel/mm/transparent_hugepage/defrag"
cat /sys/kernel/mm/transparent_hugepage/defrag
echo "Current setting for /sys/kernel/mm/transparent_hugepage/enabled"
cat /sys/kernel/mm/transparent_hugepage/enabled
echo "===================================================================="

echo
echo
echo "replace in /etc/default/grub : "
echo GRUB_CMDLINE_LINUX_DEFAULT="transparent_hugepage=never nosplash "
echo
echo "then run: update-grub"
echo


###############################
# further links for hugepages #
###############################
# http://forums.fedoraforum.org/showthread.php?t=285246
# https://bugzilla.redhat.com/show_bug.cgi?id=879801
# http://unix.stackexchange.com/questions/161858/arch-linux-becomes-unresponsive-from-khugepaged
