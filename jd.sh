if [ ! -h /etc/os-release ] ; then
  echo nie wiem co to za OS - wychodze
  echo nie wiem co to za OS - wychodze
  echo nie wiem co to za OS - wychodze
  echo nie wiem co to za OS - wychodze
  echo nie wiem co to za OS - wychodze
  echo nie wiem co to za OS - wychodze
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

