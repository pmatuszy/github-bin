#!/bin/bash
# 2022.02.20 - v. 0.3 - zmiana nazwy komputera i dodano mkdir -p
# 2021.04.09 - v. 0.2 - changed IP to machine DNS name 
# 2020.0x.xx - v. 0.1 - initial release (date unknown)


. /root/bin/_script_header.sh

set +x

echo
echo
echo  pgm-che
echo
echo

mkdir -p /mnt/pgm-che/DyskC /mnt/pgm-che/DyskD /mnt/pgm-che/DyskE /mnt/pgm-che/DyskF

read -p "Wpisz haslo: " -s PASSWD ; echo


loc_dir_name="/mnt/pgm-che/DyskC"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskC"
umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

loc_dir_name="/mnt/pgm-che/DyskD"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskD"
umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

loc_dir_name="/mnt/pgm-che/DyskE"
rem_dir_name="//pgm-che.eth.che.matuszyk.com/DyskE"
umount "${loc_dir_name}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"

df -hP |egrep 'Filesystem|pgm-che.eth.che.matuszyk.com'

set +x

. /root/bin/_script_footer.sh

