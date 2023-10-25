#!/bin/bash

# 2023.10.25 - v. 1.3 - added check if hdparm is installed
# 2023.09.02 - v. 1.2 - bugfix: better OS detection 
# 2023.07.19 - v. 1.1 - bugfix: handling wrong partition table (it was prompted, now it is removed with echo q
# 2023.07.19 - v. 1.0 - bugfix: egrep and $? checking 
# 2023.06.21 - v. 0.9 - check if nvme is installed
# 2023.03.07 - v. 0.8 - added script_header and footer calls
# 2022.11.10 - v. 0.7 - added S/N printing for NVME devices and replaced echo with printf to beautify output
# 2022.10.27 - v. 0.6 - bugfixes, added support for Raspbian, small changes in print format output,added printing of the script version
# 2022.10.11 - v. 0.5 - discovery if it is x86 or raspberry pi
# 2021.04.16 - v. 0.4 - checking if it is redhat system
# 2020.11.27 - v. 0.3 - added printing of the disk serial numbers
# 2020.10.09 - v. 0.2 - small cosmetic modifications
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [[ ! -f /etc/os-release && ! -f /etc/redhat-release ]] ; then
  echo ; echo "(PGM) I don't know what OS is that - I am exiting..." ; echo
  exit 1
fi

check_if_installed nvme nvme-cli
check_if_installed hdparm

echo 

if [[ `cat /etc/os-release /etc/redhat-release 2>/dev/null |grep -qi centos ; echo $?` == 0 ]] ; then
  echo CENTOS | boxes -s 40x5 -a c ; echo 
fi

hardware_type=""
if [[ $(uname --machine) == "x86_64" ]] ; then
   hardware_type="Intel"
fi
if [[ $(uname --machine) == "aarch64" || $(uname --machine) == "armv7l" || $(uname --machine)  == "armv6l" ]] ; then
   hardware_type="PI"
fi

echo $hardware_type | boxes -s 40x5 -a c ; echo 
egrep -qi "ubuntu|Raspbian" /etc/os-release /etc/redhat-release

if [[ $? == 0 ]] ; then
  for p in `fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|awk '{print $2}'|sort|tr -d :`;do
     if [[ `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'|wc -l` == 0 ]]; then   # no S/N - I assume it is NVME disk...
       printf "%-45s" "`gdisk -l $p |grep "Disk /dev"`"
       printf "  Serial Number: %-20s\n" "$(nvme list | grep $p | awk '{print $2}')"
     else
       printf "%-45s" "` echo q | gdisk -l $p 2>/dev/null |grep "Disk /dev"`" |sed 's|Your answer: ||g';
       printf "%-45s\n" "$(hdparm -I $p 2>/dev/null | grep 'Serial\ Number')" | sed 's|  *| |g'
     fi
  done

  echo
  echo "# of disks in the system: "$(fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l)
fi

echo

. /root/bin/_script_footer.sh

