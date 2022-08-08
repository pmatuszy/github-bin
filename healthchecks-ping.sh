#!/bin/bash
# 2022.05.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
. /root/bin/_script_footer.sh
exit

######
template crontab entry:

* * * * *   sleep $((RANDOM \% 60)) && /root/bin/healthchecks-ping.sh
