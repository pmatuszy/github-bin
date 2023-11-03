#!/bin/bash

# 2023.08.10 - v. 0.7 - bugfix: checking if ${DOKAD} exists and if not exiting
# 2023.05.22 - v. 0.6 - std_options are different for interactive and non-interactive session
# 2023.05.20 - v. 0.5 - allow script to use keychain
# 2023.05.20 - v. 0.4 - added calls for _script_header and _script_footer
# 2023.04.11 - v. 0.3 - bugfix: if source catalog doesn't exists we do not try to copy stuff
# 2023.03.03 - v. 0.2 - bugfix release: awk calculation fix
# 2023.01.31 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export SKAD_HOST="backupche.eth.che.matuszyk.com"
export SKAD_DIR="/worek-samba/nagrania/BBC4"
export DOKAD="/mnt/luks-raid1-A/video-1dyne-kopie/BBC4-ARCHIWUM"

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo
echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M:%S'`" ; echo ;

echo ; echo "SKAD  = $SKAD_HOST:$SKAD_DIR" ; echo "DOKAD = $DOKAD" ; echo ; echo

if (( $script_is_run_interactively == 1 )); then
  std_options='-a -v --stats --bwlimit=90000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files'
else
  std_options='-a -v --stats --bwlimit=90000 --no-compress --partial  --inplace --remove-source-files'
fi

if [ ! -d "${DOKAD}" ];then
  echo "(PGM) ${DOKAD} doesn't exist"
  exit 1
fi

echo "Wszystkie pliki:"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} 2>/dev/null || exit 1; /bin/ls -1tr"
kod_powrotu=$?

if (( $kod_powrotu != 0 ));then
  echo ; echo "Nie moge zmienic katalogu na $DOKAD na serwerze $SKAD_HOST ...";echo
  exit 2
fi

ile_plikow=$(ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr" | wc -l)

if (( $ile_plikow == 1 )) ; then
  echo ; echo "nie ma plikow do skopiowania, wychodze...";echo
  exit 0
fi

echo ; echo "Pliki do skopiowania:"
       echo "~~~~~~~~~~~~~~~~~~~~~"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1"

echo ; echo "Plik do zostawienia:"
       echo "~~~~~~~~~~~~~~~~~~~~"
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -1tr | tail -n-1"

echo ; echo -n "Skopiujemy "
ssh "${SKAD_HOST}" "cd ${SKAD_DIR} ; /bin/ls -ltr | head -n-1 " | awk 'BEGIN {suma=0} {suma=suma+$5} END {print suma/1024/1024 " MB danych"}'

echo ; df -h $DOKAD ; echo
echo "Poczatek kopiowania: $(date '+%Y.%m.%d %H:%M:%S')" ; echo

rsync $std_options -e "ssh -T -o Compression=no -x" --files-from=<(ssh $SKAD_HOST "cd ${SKAD_DIR} ; /bin/ls -1tr | head -n-1" ) "${SKAD_HOST}:${SKAD_DIR}" "${DOKAD}"

echo "koniec: $(date '+%Y.%m.%d %H:%M:%S')" ; echo

. /root/bin/_script_footer.sh
