#!/bin/bash

# 2025.10.22 - v. 0.2 - bugfix: added check if vmware utility exists
# 2024.11.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

export DISPLAY=

type -fP vmware 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmware program... exiting ..."; echo
  exit 1
fi

echo vmware --version
echo ; echo 
vmware --version
echo
