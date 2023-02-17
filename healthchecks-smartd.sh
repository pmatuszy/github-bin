#!/bin/bash

# 2023.01.16 - v. 0.3 - better service restart failure detection, redirection of 2> on 1>
# 2023.01.03 - v. 0.2 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.18 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; echo ;
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     systemctl restart smartd --no-pager 2>&1
     kod_powrotu=$?
     sleep 5 ; echo ; echo "STATUS PO RESTARCIE SERWISU: " ; echo
     systemctl status smartd --no-pager ; echo ; exit $kod_powrotu )
wynik_po_restarcie=$?

wiadomosc=""
if (( $(echo "$m" |grep -i "error" | wc -l) > 0 )) || (( $wynik_po_restarcie != 0 )) ;then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

######
template crontab entry:

@reboot ( sleep 45 && /root/bin/healthchecks-smartd.sh) 2>&1

0 18 * * *  sleep $((RANDOM \% 60)) && /root/bin/healthchecks-smartd.sh
