#!/bin/bash

# 2024.03.12 - v. 0.3 - bugfix release
# 2024.03.12 - v. 0.2 - added how_many_retries and retry_delay
# 2023.02.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

URL=www.anna.matuszyk.com  ; export URL
blad=1
how_many_retries=10
retry_delay=15

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  if [ $(wget $URL -qO - |grep "In Short"|wc -l) -gt 0 ];then 
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/nulla
    blad=0
    break
  else 
    sleep $retry_delay
  fi
done

if (( $blad != 0 ));then
   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null

fi

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry

*/15 * * * * /root/bin/sprawdz-czy-dziala-strona-www.anna.matuszyk.com.sh
