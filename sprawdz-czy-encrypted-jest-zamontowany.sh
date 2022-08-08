#!/bin/bash
# 2022.05.12 - v. 0.1 - usunieta zmienna m, ktora nie byla uzywana
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ `mountpoint -q /encrypted ; echo $?` -ne 0 ] ; then 
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

6 * * * * sleep $((RANDOM \% 60)) && /root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
