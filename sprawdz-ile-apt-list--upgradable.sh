#!/bin/bash
# 2022.05.05 - v. 0.2 - dodany uptime i hostname
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

ile_max_by_nie_raportowac=40

/usr/bin/apt-get update 2>&1 >/dev/null

ile_jest_do_upgradeowania=$(/usr/bin/apt list --upgradable 2>/dev/null | grep -v "Listing..." |wc -l)

m=$(echo ile_jest_do_upgradeowania = $ile_jest_do_upgradeowania ; echo ile_max_by_nie_raportowac = $ile_max_by_nie_raportowac ; 
    echo "uptime: `uptime`"; echo "hostname: `hostname`";
    /usr/bin/apt list --upgradable 2>&1|egrep -v "WARNING: apt does not have a stable CLI interface. Use with caution in scripts.|Listing...")

if [ $ile_jest_do_upgradeowania -gt $ile_max_by_nie_raportowac ];then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

@reboot ( sleep 60 && /root/bin/sprawdz-ile-apt-list--upgradable.sh ) 2>&1
2 */6 * * * /root/bin/sprawdz-ile-apt-list--upgradable.sh
