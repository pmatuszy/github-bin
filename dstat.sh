#!/bin/bash

# 2023.10.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed dstat

type -fP dstat 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find dstat utility... exiting ..."; echo 
  exit 1
fi

dstat -tcdnmg -D mmcblk0 -N eth0 -C total --top-cpu --top-io --top-mem --cpufreq -f 5

. /root/bin/_script_footer.sh
