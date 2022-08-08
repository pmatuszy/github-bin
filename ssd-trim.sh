#!/bin/bash

# 2022.04.30 - v. 0.2 - added healthcheck support
# 2021.02.24 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

m=$( /sbin/fstrim  --verbose --all 2>&1)

if [ -f "$HEALTHCHECKS_FILE" ];then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit

######
template crontab entry:

@reboot ( sleep 45 && /root/bin/ssd-trim.sh) 2>&1
0 */4 * * *    sleep $((RANDOM \% 60)) &&  /root/bin/ssd-trim.sh
