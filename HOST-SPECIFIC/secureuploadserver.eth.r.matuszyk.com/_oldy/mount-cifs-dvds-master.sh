#!/bin/bash
# 2021.04.20 - v. 0.1 - single password prompt only
# 2020.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

loc_dir_name="/mnt/rsync-master-DVDs"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/DVDs"

echo
echo
echo "skad  : $rem_dir_name"
echo "dokad : $loc_dir_name"
echo
echo

read -p "Enter password: " -s PASSWD

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"

mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}" 
df -hP "${loc_dir_name}"

. /root/bin/_script_footer.sh
