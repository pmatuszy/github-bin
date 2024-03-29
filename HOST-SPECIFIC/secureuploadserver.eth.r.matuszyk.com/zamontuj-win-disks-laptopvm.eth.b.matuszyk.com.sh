#!/bin/bash
# 2022.12.31 - v. 0.3 - this script should mount nothing from now on
# 2022.09.11 - v. 0.2 - zmiany kosmetyczne o KeePassie
# 2022.07.30 - v. 0.1 - initial release

. /root/bin/_script_header.sh

remote_server=laptopvm.eth.b.matuszyk.com

echo 
echo 
echo  "remote_server = $remote_server"
echo 
echo 


echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
echo NIC NIE MONTUJEMY Z TEGO SERWERA !!!!
exit 1


echo ; echo "w KeePassie:" ; echo "Samba (p @ laptopvm.eth.b.matuszyk.com)"
read -p "Wpisz haslo: " -s PASSWD ; echo 


loc_dir_name="/mnt/rsync-master-DivX"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/DivX-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-DVDs"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/DVDs-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-ksiazki"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/ksiazki-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-mp3"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/mp3-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-_na_DVD"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/_na_DVD-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-SkyPlus"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/SkyPlus-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"

loc_dir_name="/mnt/rsync-master-BBC"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/BBC-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


df -hP |egrep 'Filesystem|laptopvm.eth.b.matuszyk.com'

# set +x

. /root/bin/_script_footer.sh
