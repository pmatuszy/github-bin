#!/bin/bash
# 2022.11.10 - v. 0.7 - added S/N printing for NVME devices and replaced echo with printf to beautify output
# 2022.10.27 - v. 0.6 - bugfixes, added support for Raspbian, small changes in print format output,added printing of the script version
# 2022.10.11 - v. 0.5 - discovery if it is x86 or raspberry pi
# 2021.04.16 - v. 0.4 - checking if it is redhat system
# 2020.11.27 - v. 0.3 - added printing of the disk serial numbers
# 2020.10.09 - v. 0.2 - small cosmetic modifications
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

if [[ ! -h /etc/os-release && ! -h /etc/redhat-release ]] ; then
  echo
  echo "nie wiem co to za OS - wychodze..."
  echo
  exit 1
fi

echo 

cat  $0|grep -e '2022'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo 

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

if [[ `cat /etc/os-release /etc/redhat-release 2>/dev/null |egrep -qi "ubuntu|Raspbian" ; echo $?` == 0 ]] ; then
  for p in `fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|awk '{print $2}'|sort|tr -d :`;do
     if [[ `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'|wc -l` == 0 ]]; then   # no S/N - I assume it is NVME disk...
#       echo `gdisk -l $p |grep "Disk /dev"` "     Serial Number: " $(nvme list | grep $p | awk '{print $2}')
       printf "%-45s" "`gdisk -l $p |grep "Disk /dev"`"
       printf "  Serial Number: %-20s\n" "$(nvme list | grep $p | awk '{print $2}')"
      
     else
       printf "%-45s" "`gdisk -l $p |grep "Disk /dev"`"
       printf "%-45s\n" "$(hdparm -I $p 2>/dev/null | grep 'Serial\ Number')" | sed 's|  *| |g'
#        echo `gdisk -l $p |grep "Disk /dev"` "   " `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'` ;
     fi
  done

  echo
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l
fi

echo
