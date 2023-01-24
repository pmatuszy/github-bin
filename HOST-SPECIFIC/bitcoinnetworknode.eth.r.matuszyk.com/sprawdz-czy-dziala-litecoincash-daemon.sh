#!/bin/bash

# 2023.01.24 - v. 0.1 - initial release

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

# spr. czy dziala tor relay
if [ $(/bin/systemctl status tor|grep "Active: active"|wc -l) -eq 0 ];then 
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

3 * * * * /root/bin/sprawdz-czy-dziala-tor-relay.sh

