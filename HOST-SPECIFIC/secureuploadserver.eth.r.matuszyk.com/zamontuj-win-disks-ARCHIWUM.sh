#!/bin/bash
# 2021.04.20 - v. 0.1 - zmiana, by bylo jedno tylko pytanie o haslo
# 2020.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

set +x 

echo 
echo 
echo  server 
echo 
echo 

#set -x

read -p "Wpisz haslo: " -s PASSWD

/mnt/rsync-master-archiwum

umount /mnt/rsync-master-archiwum 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"

mount.cifs -o user=p,password=$PASSWD //lublin.eth.b.matuszyk.com/buffalo1/_z_servera/O /mnt/rsync-master-archiwum ; df -hP /mnt/rsync-master-archiwum

# set +x

. /root/bin/_script_footer.sh
