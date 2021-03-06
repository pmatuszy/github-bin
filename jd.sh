#!/bin/bash
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

if [[ `cat /etc/os-release /etc/redhat-release 2>/dev/null |grep -qi centos ; echo $?` == 0 ]] ; then
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~ CENTOS ~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  for p in `fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort|tr -d :`;do
     echo `gdisk -l $p |grep "Disk /dev"` "   " `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'`
  done

  echo
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l
else
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~ PI  ~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  
#  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort
  for p in `fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|awk '{print $2}'|sort|tr -d :`;do
     echo `gdisk -l $p |grep "Disk /dev"` "   " `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'`
  done

  echo
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l
fi

echo
