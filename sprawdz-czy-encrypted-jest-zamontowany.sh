#!/bin/bash
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ `mountpoint -q /encrypted ; echo $?` -ne 0 ] ; then 
  (echo "zamountuj /encrypted " | strings | aha | mailx -r root@`hostname` -a 'Content-Type: text/html' -r root@`hostname` -s "(`/bin/hostname`) 
  /encrypted NIE jest zamontowany (`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) " matuszyk+`/bin/hostname`@matuszyk.com) 
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

6 6-23/4 * * * /root/bin/sprawdz-czy-dziala-server-vpn.sh

