#!/bin/bash

# 2022.12.31 - v. 0.3 - dodalem funkcje zamontuj_via_nfs
# 2022.09.11 - v. 0.2 - zmiany kosmetyczne o KeePassie
# 2022.07.30 - v. 0.1 - initial release

. /root/bin/_script_header.sh

remote_server=lublin.eth.b.matuszyk.com

echo
echo  "remote_server = $remote_server"
echo

echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

echo ; echo "w KeePassie:" ; echo  "Samba (p @ lublin.eth.r.matuszyk.com)"

read -p "Wpisz haslo: " -s PASSWD ; echo

###############################################################################################################
###############################################################################################################
zamontuj_via_nfs() {
umount "${2}" 2>/dev/null  # just in case sa zamontowane, by nie dostawac komunikatu "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${1}" "${2}"

if (( $? == 0 ));then
  echo "${2} was mounted without problems"
else
  echo "${2} was NOT mounted !!!!"
fi
}
###############################################################################################################
###############################################################################################################

zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/archiwum-MASTER-SOURCE_read_only"  "/mnt/rsync-master-archiwum"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/rsync-master-BBC_read_only"        "/mnt/rsync-master-BBC"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/DivX-MASTER-SOURCE_read_only"      "/mnt/rsync-master-DivX"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/DVDs-MASTER-SOURCE_read_only"      "/mnt/rsync-master-DVDs"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/ksiazki-MASTER-SOURCE_read_only"   "/mnt/rsync-master-ksiazki"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/mp3-MASTER-SOURCE_read_only"       "/mnt/rsync-master-mp3"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/_na_DVD-MASTER-SOURCE_read_only"   "/mnt/rsync-master-_na_DVD"
zamontuj_via_nfs "//lublin.eth.r.matuszyk.com/SkyPlus-MASTER-SOURCE_read_only"   "/mnt/rsync-master-SkyPlus"

df -hP |egrep 'Filesystem|lublin.eth.r.matuszyk.com'

. /root/bin/_script_footer.sh
