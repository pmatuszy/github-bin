#!/bin/bash

# 2023.01.30 - v. 0.4 - beautify output, rsync is called once
# 2023.01.16 - v. 0.3 - addd sleep 0.5
# 2023.01.10 - v. 0.2 - print files on the source file
# 2023.01.09 - v. 0.1 - initial release

export SKAD_HOST="backupche.eth.che.matuszyk.com"
export SKAD_DIR="/worek-samba/nagrania/Kijow-webcamy"
export DOKAD="/mnt/luks-lv-icybox-A/video-1dyne-kopie/Kijow-webcamy-ARCHIWUM/"

echo ; echo "SKAD  = $SKAD_HOST:$SKAD_DIR" ; echo "DOKAD = $DOKAD" ; echo ; echo
std_options="-a -v --stats --bwlimit=90000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files "

echo "Wszystkie pliki:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr"

echo ; echo "Pliki do skopiowania:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1"

echo ; echo "Plik do zostawienia:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | tail -n-1"

echo -n "skopiujemy "

ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; stat -c '%s' *" | awk 'BEGIN {$suma=0} {$Suma=$suma+$0} END {print $suma/1024/1024 " MB danych"}'

echo ; df -h $DOKAD ; echo

echo "Poczatek kopiowania: $(date '+%Y.%m.%d %H:%M:%S')" ; echo 

rsync $std_options --files-from=<(ssh $SKAD_HOST "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1" ) "${SKAD_HOST}:${SKAD_DIR}" "${DOKAD}"

echo "koniec: $(date '+%Y.%m.%d %H:%M:%S')" ; echo
