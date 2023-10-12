#!/bin/bash

# 2023.10.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed dstat

type -fP dstat 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find dstat utility... exiting ..."; echo 
  exit 1
fi

clear 

if (( $# == 0 ));then
 dstat -tcdnmg -D mmcblk0,nvme0n1,/dev/sd* -N ens33,eth0,eno1 -C total --top-cpu --top-io --top-mem --cpufreq -C total --bw --nocolor -f 1
else
 dstat -tcdnmg -D mmcblk0,nvme0n1,/dev/sd* -N ens33,eth0,eno1 -C total --top-cpu --top-io --top-mem --cpufreq -C total --bw --nocolor --noupdate -f $1
fi

. /root/bin/_script_footer.sh
