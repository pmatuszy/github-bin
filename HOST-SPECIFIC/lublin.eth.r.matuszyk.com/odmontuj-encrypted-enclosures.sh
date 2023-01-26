#!/bin/bash

# 2023.01.26 - v. 0.2 - added script version print
# 2022.11.21 - v. 0.1 - initial release

. /root/bin/_script_header.sh

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo 

################################################################################
odmontuj_fs_MASTER() {
echo ; echo "==> ########## odmontuj_fs_MASTER($1)"

if [ $(mountpoint -q $1 ; echo $?) -ne 0 ] ; then
   echo $1 NIE jest juz zamontowany ... wychodze
   echo "<== ########## odmontuj_fs_MASTER($1)"
   return 
fi

luks_device="$(df -h $1 | grep $1  | awk '{print $1}')"

umount $1 

if (( $? != 0 ));then
  echo  ; echo "NIE MOGE ODZAMONTOWAC $1  !!!!!!!"; echo "wychodze ..."
  echo "<== ########## odmontuj_fs_MASTER($1)"
  umount -l $1
  sleep 5
else
  echo "dismount zrobiony"
fi

sleep 1 

echo cryptsetup luksClose ${luks_device}
cryptsetup luksClose ${luks_device}

if (( $? != 0 ));then
  echo  ; echo "NIE MOGE ZAMKNAC LUKS DEVICEa $1 !!!!!!!"; echo "wychodze ..."
  echo "<== ########## odmontuj_fs_MASTER($1)"
  return
else
  echo "luksClose zrobiony"
fi

echo "<== ########## odmontuj_fs_MASTER($1)"
}
################################################################################

odmontuj_fs_MASTER /mnt/luks-dyskD
odmontuj_fs_MASTER /mnt/luks-buffalo1
