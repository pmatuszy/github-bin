#!/bin/bash

# 2022.05.09 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

# spr. czy nie ma bledow
if [ $(apcaccess |grep "STATUS   : ONLINE$"|wc -l) -eq 0 ];then
  m=$( /usr/sbin/apcaccess  2>&1)
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit

0 */1 * * *    sleep $((RANDOM % 60)) && /root/bin/apc-status.sh
