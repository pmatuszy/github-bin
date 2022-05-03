#!/bin/bash
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

ile_max_by_nie_raportowac=2

/usr/bin/apt-get update 2>&1 >/dev/null

ile_jest_do_upgradeowania=$(/usr/bin/apt-get list --upgradable 2>/dev/null|wc -l)

if [ $ile_jest_do_upgradeowania -gt $ile_max_by_nie_raportowac ];then 
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

2 6 * * * /root/bin/sprawdz-czy-dziala-server-vpn.sh
