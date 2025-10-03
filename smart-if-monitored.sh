#!/bin/bash

# 2025.10.02 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed smartctl smartmontools

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, I will run the script against ALL disks found on this systems..."
    echo "searching for disks..."
    disks=$(jd.sh 2>/dev/null |grep Disk |sed 's|:.*||g'|sed 's|Disk ||g')
    sleep 2
else
  disks=$1
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="--info -A "
export SMARTCTL_BIN=$(type -fP smartctl)

if (( script_is_run_interactively ));then
   clear
fi
echo;echo
echo $p | boxes -s 40x5 -a c ; echo


. /root/bin/_script_footer.sh

