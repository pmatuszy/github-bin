#!/bin/bash
# 2022.05.11 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export RESTIC_BIN=$(type -fP restic)
if pgrep -f "${RESTIC_BIN}" > /dev/null ; then
  m=$(
  echo '#####################################################'
  echo '#####################################################'
  echo
  echo "${RESTIC_BIN} dziala, wiec nie startuje nowej instancji a po prostu koncze dzialanie skryptu"
  echo
  echo '#####################################################'
  echo '#####################################################' )
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 1
fi

wersja_przed=$(echo " " ; echo " " ; echo "wersja przed: " ; ${RESTIC_BIN} version ; echo " ")
m=$( echo " "; /usr/bin/restic self-update ; exit $?)
kod_powrotu=$?
wersja_po=$(echo " " ; echo "wersja po: "; "${RESTIC_BIN}" version ; echo " " ; echo " ")

if [ $kod_powrotu -ne 0 ]; then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m $wersja_przed $wersja_po" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit $kod_powrotu # cos poszlo nie tak
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m $wersja_przed $wersja_po" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit
#####
# new crontab entry

0 20 * * * sleep $((RANDOM \% 60)) && /root/bin/update-restic.sh
