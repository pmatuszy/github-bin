#!/bin/bash

# 2025.11.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

check_if_installed sensors nvme-cli
echo aa
export DISPLAY=

type -fP sensors 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find sensors utility... exiting ..."; echo
  exit 1
fi

watch -n 0.2 sensors

. /root/bin/_script_footer.sh

