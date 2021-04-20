#!/bin/bash
# 2021.04.20 - v. 0.1 - zmiana, by bylo jedno tylko pytanie o haslo
# 2020.xx.xx - v. 0.1 - initial release

. /root/_script_header.sh

set +x 

echo 
echo 
echo  server 
echo 
echo 

#set -x

read -p "Wpisz haslo: " -s PASSWD

umount /mnt/server/Dysk?  2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"

mount.cifs -o user=administrator,password=$PASSWD //server.int.matuszyk.com/DyskC /mnt/server/DyskC ; df -hP /mnt/server/DyskC
mount.cifs -o user=administrator,password=$PASSWD  //server.int.matuszyk.com/DyskD /mnt/server/DyskD ; df -hP /mnt/server/DyskD
mount.cifs -o user=administrator,password=$PASSWD //server.int.matuszyk.com/DyskN /mnt/server/DyskN ; df -hP /mnt/server/DyskN
mount.cifs -o user=administrator,password=$PASSWD //server.int.matuszyk.com/DyskO /mnt/server/DyskO ; df -hP /mnt/server/DyskO

# set +x

. /root/_script_footer.sh
