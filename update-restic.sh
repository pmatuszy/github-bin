#!/bin/bash

# 2023.12.18 - v. 0.7 - bugfix: check if restic is installed
# 2023.03.26 - v. 0.6 - added ile_prob i odstepy_miedzy_probami_sek
# 2023.02.28 - v. 0.5 - curl with kod_powrotu
# 2023.01.03 - v. 0.4 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.20 - v. 0.3 - dodalem wypisywanie aktualnej daty
# 2022.05.12 - v. 0.2 - small bux fix (use RESTIC_BIN intsead of /usr/bin/restic)
# 2022.05.11 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export ile_prob=10
export odstepy_miedzy_probami_sek=20

check_if_installed restic

export RESTIC_BIN=$(type -fP restic)

if [ -z "${RESTIC_BIN}" ] ; then
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "Restic is not installed"
    echo
    echo '#####################################################'
    echo '#####################################################' 
    )
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 8
fi
if pgrep -f "${RESTIC_BIN}" > /dev/null ; then
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "${RESTIC_BIN} dziala, wiec nie startuje nowej instancji a po prostu koncze dzialanie skryptu"
    echo
    echo '#####################################################'
    echo '#####################################################' 
    )
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 1
fi

wersja_przed=$(echo " " ; echo " " ; echo "wersja przed: " ; ${RESTIC_BIN} version 2>&1; echo " ")
m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     for (( p=1 ; p<=$ile_prob;p++)) ;do
       "${RESTIC_BIN}" self-update 2>&1 
       if (( $? == 0 )); then
         echo "Update done with no problems"
         exit 0
       else
         echo "$(date '+%Y.%m.%d %H:%M') Update unsucessful - retrying in $odstepy_miedzy_probami_sek seconds)"
         sleep $odstepy_miedzy_probami_sek
       fi
     done
     exit $? 
   )
kod_powrotu=$?
wersja_po=$(echo " " ; echo "wersja po: "; "${RESTIC_BIN}" version 2>&1; echo " " ; echo " ")

wiadomosc=""
if [ $(echo "$m" |grep "restic is up to date" | wc -l) -eq 1 ];then
  wiadomosc=$(echo "$m" |grep "restic is up to date" ; "${RESTIC_BIN}" version|head -n 1)
else
  wersja_po=$(echo " " ; echo "wersja po: "; "${RESTIC_BIN}" version 2>&1; echo " " ; echo " ")
  wiadomosc="$m $wersja_przed $wersja_po"
fi

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}
#####
# new crontab entry

0 20 * * * /root/bin/update-restic.sh
