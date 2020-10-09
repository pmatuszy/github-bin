#!/bin/bash
# 2020.10.09 - v. 0.2 - small cosmetic modifications
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

if [ ! -h /etc/os-release ] ; then
  echo
  echo "nie wiem co to za OS - wychodze..."
  echo
  exit 1
fi



if [[ `cat /etc/os-release |grep -qi centos ; echo $?` == 0 ]] ; then
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~ CENTOS ~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort
  echo
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l
else
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~ PI  ~~~~~~~~~~~~~"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort
  echo
  fdisk -l|grep 'Disk /dev'|egrep -v 'mapper|/md|/ram|mmcb|/dev/loop'|sort | wc -l
fi

echo

