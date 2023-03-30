#!/bin/bash

# 2023.01.31 - v. 0.1 - initial release

export SKAD_HOST="backupche.eth.che.matuszyk.com"
export SKAD_DIR="/worek-samba/nagrania/BBC4"
export DOKAD="/mnt/luks-icybox10/video-1dyne-kopie/BBC4-ARCHIWUM"

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo
echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;

echo ; echo "SKAD  = $SKAD_HOST:$SKAD_DIR" ; echo "DOKAD = $DOKAD" ; echo ; echo
std_options='-a -v --stats --bwlimit=90000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files'

echo "Wszystkie pliki:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr"
ile_plikow=$(ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr" | wc -l)

if (( $ile_plikow == 1 )) ; then
  echo ; echo "nie ma plikow do skopiowania, wychodze...";echo
  exit 0
fi

echo ; echo "Pliki do skopiowania:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1"

echo ; echo "Plik do zostawienia:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | tail -n-1"

echo ; echo -n "Skopiujemy "
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -ltr | head -n-1 " | awk 'BEGIN {$suma=0} {$Suma=$suma+$5} END {print $suma/1024/1024 " MB danych"}'

echo ; df -h $DOKAD ; echo
echo "Poczatek kopiowania: $(date '+%Y.%m.%d %H:%M:%S')" ; echo

rsync $std_options -e "ssh -T -o Compression=no -x" --files-from=<(ssh $SKAD_HOST "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1" ) "${SKAD_HOST}:${SKAD_DIR}" "${DOKAD}"

echo "koniec: $(date '+%Y.%m.%d %H:%M:%S')" ; echo

