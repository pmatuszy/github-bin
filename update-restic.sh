#!/bin/bash
# 2022.05.20 - v. 0.3 - dodalem wypisywanie aktualnej daty
# 2022.05.12 - v. 0.2 - small bux fix (use RESTIC_BIN intsead of /usr/bin/restic)
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

wersja_przed=$(echo " " ; echo " " ; echo "wersja przed: " ; ${RESTIC_BIN} version 2>&1; echo " ")
m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; "${RESTIC_BIN}" self-update 2>&1 ; exit $?)
kod_powrotu=$?
wersja_po=$(echo " " ; echo "wersja po: "; "${RESTIC_BIN}" version 2>&1; echo " " ; echo " ")

wiadomosc=""
if [ $(echo "$m" |grep "restic is up to date" | wc -l) -eq 1 ];then
  wiadomosc=$(echo "$m" |grep "restic is up to date" ; "${RESTIC_BIN}" version|head -n 1)
else
  wersja_po=$(echo " " ; echo "wersja po: "; "${RESTIC_BIN}" version 2>&1; echo " " ; echo " ")
  wiadomosc="$m $wersja_przed $wersja_po"
fi

if [ $kod_powrotu -ne 0 ]; then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit $kod_powrotu # cos poszlo nie tak
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit
#####
# new crontab entry

0 20 * * * sleep $((RANDOM \% 60)) && /root/bin/update-restic.sh
