#!/bin/bash
# 2022.12.29 - v. 0.1 - initial release

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

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     lvs
     lvs -o sync_percent|grep -v "Cpy%Sync"|sort|uniq|grep 100.00|wc -l 2>&1; exit $?
   )
kod_powrotu=$?

if [ $kod_powrotu -ne 0 ]; then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit $kod_powrotu # cos poszlo nie tak
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit
#####
# new crontab entry

@reboot /root/bin/healthchecks-lvs-sync-status.sh

0 * * * * /root/bin/healthchecks-lvs-sync-status.sh

