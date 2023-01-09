#!/bin/bash

DOKAD="/mnt/luks-lv-icybox-A/video-1dyne-kopie/Kijow-webcamy-ARCHIWUM/"

echo ; echo DOKAD $DOKAD ; echo ; echo
std_options="-a -v --stats --bwlimit=90000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files "
for p in $(ssh backupche.eth.che.matuszyk.com "ls -1t /worek-samba/nagrania/Kijow-webcamy/" |tail -n+2);do 
  rsync $std_options backupche.eth.che.matuszyk.com:/worek-samba/nagrania/Kijow-webcamy/$p "${DOKAD}"
done

