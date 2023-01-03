#!/bin/bash
# 2022.06.15 - v. 0.3 - dodanie czekania jesli apt-get update jest wykonywany w tym samym czasie przez inny proces
# 2022.05.05 - v. 0.2 - dodany uptime i hostname
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}
tty 2>&1 >/dev/null
if (( $? != 0 )); then      # we set RANDOM_DELAY only when running NOT from terminal
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  sleep $RANDOM_DELAY
else
  echo ; echo "Interactive session detected: I will NOT introduce RANDOM_DELAY..."
fi

ile_max_by_nie_raportowac=45

/usr/bin/apt-get update &>/dev/null      # &> filename redirects STDOUT and STDERR to filename
kod_powrotu=$?
if [ $kod_powrotu -ne 0 ]; then
  sleep 100
fi

# let's give it another chance
/usr/bin/apt-get update &>/dev/null      # &> filename redirects STDOUT and STDERR to filename
kod_powrotu=$?
if [ $kod_powrotu -ne 0 ]; then
   m="apt update jest uruchomione na innym terminalu i nie moge dostac locka wiec wychodze"
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "${m}" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 2
fi

ile_jest_do_upgradeowania=$(/usr/bin/apt list --upgradable 2>/dev/null | grep -v "Listing..." |wc -l)

m=$(echo ile_jest_do_upgradeowania = $ile_jest_do_upgradeowania ; echo ile_max_by_nie_raportowac = $ile_max_by_nie_raportowac ; 
    echo "uptime: `uptime`"; echo "hostname: `hostname`";
    /usr/bin/apt list --upgradable 2>&1|egrep -v "WARNING: apt does not have a stable CLI interface. Use with caution in scripts.|Listing...")

if [ $ile_jest_do_upgradeowania -gt $ile_max_by_nie_raportowac ];then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

@reboot ( sleep 60 && /root/bin/sprawdz-ile-apt-list--upgradable.sh ) 2>&1
2 */6 * * * /root/bin/sprawdz-ile-apt-list--upgradable.sh
