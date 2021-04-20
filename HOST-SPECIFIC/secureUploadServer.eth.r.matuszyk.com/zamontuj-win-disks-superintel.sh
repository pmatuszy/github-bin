#!/bin/bash
# 2021.04.20 - v. 0.1 - zmiana, by bylo jedno tylko pytanie o haslo
# 2020.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

# mount -o remount /mnt/superintel/DyskC
# mount -o remount /mnt/superintel/DyskD
# mount -o remount /mnt/superintel/DyskE
# mount -o remount /mnt/superintel/DyskS
# mount -o remount /mnt/superintel/DyskT
# mount -o remount /mnt/superintel/DyskU

echo 
echo 
echo superintel 
echo 
echo 

read -p "Wpisz haslo: " -s PASSWD
echo 

umount /mnt/superintel/Dysk?  2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
sleep 1

mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskC /mnt/superintel/DyskC ; df -hP /mnt/superintel/DyskC
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskD /mnt/superintel/DyskD ; df -hP /mnt/superintel/DyskD
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskE /mnt/superintel/DyskE ; df -hP /mnt/superintel/DyskE
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskI /mnt/superintel/DyskI ; df -hP /mnt/superintel/DyskI
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskS /mnt/superintel/DyskS ; df -hP /mnt/superintel/DyskS
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskT /mnt/superintel/DyskT ; df -hP /mnt/superintel/DyskT
mount.cifs -o user=administrator,password=$PASSWD //superintel.eth.b.matuszyk.com/DyskU /mnt/superintel/DyskU ; df -hP /mnt/superintel/DyskU

. /root/bin/_script_footer.sh
