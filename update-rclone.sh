#!/bin/bash

# 2023.01.03 - v. 0.3 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.20 - v. 0.2 - dodalem wypisywanie aktualnej daty
# 2022.05.11 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export RCLONE_BIN=$(type -fP rclone)

# nie badamy czy rclone jest uruchomiony, bo moze byc rclone mount i on jest zawsze uruchomiony. My updateujemy mimo to
# nie badamy czy rclone jest uruchomiony, bo moze byc rclone mount i on jest zawsze uruchomiony. My updateujemy mimo to
# nie badamy czy rclone jest uruchomiony, bo moze byc rclone mount i on jest zawsze uruchomiony. My updateujemy mimo to
# nie badamy czy rclone jest uruchomiony, bo moze byc rclone mount i on jest zawsze uruchomiony. My updateujemy mimo to

# if pgrep -f "${RCLONE_BIN}" > /dev/null ; then
#   m=$(
#   echo '#####################################################'
#   echo '#####################################################'
#   echo
#   echo "${RCLONE_BIN} dziala, wiec nie startuje nowej instancji a po prostu koncze dzialanie skryptu"
#   echo
#   echo '#####################################################'
#   echo '#####################################################' )
#   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
#   exit 1
# fi

wersja_przed=$(echo " " ; echo " " ; echo "wersja przed: " ; "${RCLONE_BIN}" version 2>&1; echo " " )
wersja_przed_short=$(echo " " ; echo " " ; echo "wersja: " ; "${RCLONE_BIN}" version|head -n 1 2>&1; echo " " )
m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; "${RCLONE_BIN}" selfupdate 2>&1; exit $?)
kod_powrotu=$?

wiadomosc=""
if [ $(echo "$m" |grep "NOTICE: rclone is up to date" | wc -l) -eq 1 ];then
  wiadomosc=$(echo "$m" |grep "NOTICE: rclone is up to date" ; "${RCLONE_BIN}" version|head -n 1)
else
  wersja_po=$(echo " " ; echo "wersja po: "; "${RCLONE_BIN}" version 2>&1; echo " " ; echo " ")
  wiadomosc="$m $wersja_przed $wersja_po"
fi

if [ $kod_powrotu -ne 0 ]; then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit $kod_powrotu # cos poszlo nie tak
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?
#####
# new crontab entry

5 20 * * * /root/bin/update-rclone.sh
