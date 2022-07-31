#!/bin/bash
# 2022.07.30 - v. 0.1 - initial release

. /root/bin/_script_header.sh

remote_server=lublin.eth.b.matuszyk.com

set +x 

echo 
echo 
echo  "remote_server = $remote_server"
echo 
echo 

#set -x

read -p "Wpisz haslo: " -s PASSWD



loc_dir_name="/mnt/rsync-master-archiwum"
rem_dir_name="//lublin.eth.b.matuszyk.com/buffalo1/_z_servera/O/archiwum"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
df -hP "${loc_dir_name}"



loc_dir_name="/mnt/rsync-master-BBC"
rem_dir_name="//lublin.eth.b.matuszyk.com/BBC-MASTER-SOURCE"

umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
df -hP "${loc_dir_name}"

# set +x

. /root/bin/_script_footer.sh
