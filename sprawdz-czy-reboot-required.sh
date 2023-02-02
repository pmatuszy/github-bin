#!/bin/bash
# 2023.01.09 - v. 0.2 - small changes (along with the random delay) and a new crontab entry after the reboot
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

@reboot ( /root/bin/sprawdz-czy-reboot-required.sh ) 2>&1

0 7-22 * * * /root/bin/sprawdz-czy-reboot-required.sh

