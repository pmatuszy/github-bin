#!/bin/bash
# 2022.06.01 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     ile_wolnego_RAM=$(free -m|grep '^Mem:'|awk '{print $7}');
     ile_zajetego_SWAP=$(free -m|grep '^Swap:'|awk '{print $3}');
     let czy_jest_wolny_ram=$ile_wolnego_RAM-$ile_zajetego_SWAP;
     if (( $czy_jest_wolny_ram > 2000 ));then
       /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
       swapoff -a ; sleep 2; swapon -a 
     else
       /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
     fi
     echo 
    )

. /root/bin/_script_footer.sh
exit

######
template crontab entry:

1 */12 * * *  sleep $((RANDOM \% 60)) && /root/bin/healthchecks-swap-usage.sh
