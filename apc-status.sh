#!/bin/bash

# 2022.05.09 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

# spr. czy nie ma bledow
if [ $(/usr/bin/env apcaccess | egrep "STATUS   : ONLINE *"|wc -l) -eq 0 ];then
  m=$( /usr/bin/env apcaccess 2>&1)
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  m=$( /usr/bin/env apcaccess 2>&1| egrep "STATUS   : ONLINE *")
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit

0 */1 * * *    sleep $((RANDOM % 60)) && /root/bin/apc-status.sh
