#!/bin/bash

# 2023.01.16 - v. 0.3 - addd sleep 0.5
# 2023.01.10 - v. 0.2 - print files on the source file
# 2023.01.09 - v. 0.1 - initial release

SKAD="backupche.eth.che.matuszyk.com:/worek-samba/nagrania/Kijow-webcamy/"
DOKAD="/mnt/luks-lv-icybox-A/video-1dyne-kopie/Kijow-webcamy-ARCHIWUM/"

echo ; echo "SKAD  = $SKAD" ; echo "DOKAD = $DOKAD" ; echo ; echo
std_options="-a -v --stats --bwlimit=90000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files "

ssh backupche.eth.che.matuszyk.com "ls -ltr /worek-samba/nagrania/Kijow-webcamy/"

for p in $(ssh backupche.eth.che.matuszyk.com "ls -1t /worek-samba/nagrania/Kijow-webcamy/" |tail -n+2);do 
  rsync $std_options backupche.eth.che.matuszyk.com:/worek-samba/nagrania/Kijow-webcamy/$p "${DOKAD}"
  sleep 0.5 # to be easier to break the execution of the script using CTRL-C
done

