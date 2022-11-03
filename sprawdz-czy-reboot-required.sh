#!/bin/bash
# 2022.11.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

# spr. czy potrzebny jest reboot
if [ -f /var/run/reboot-required ];then 
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit

#####
# new crontab entry

1 * * * * sleep $((RANDOM \% 50)) && /root/bin/sprawdz-czy-reboot-required.sh

