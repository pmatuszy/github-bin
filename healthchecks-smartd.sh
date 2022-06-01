#!/bin/bash
# 2022.05.18 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi


m=$( echo " ";
     systemctl restart smartd --no-pager  ; sleep 5 ; echo ; echo "STATUS PO RESTARCIE SERWISU: " ; echo
     systemctl status smartd --no-pager ; echo )

wiadomosc=""
if [ $(echo "$m" |grep -i "error" | wc -l) -gt 0 ];then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh
exit

######
template crontab entry:

@reboot ( sleep 45 && /root/bin/healthchecks-smartd.sh) 2>&1

0 18 * * *  sleep $((RANDOM \% 60)) && /root/bin/healthchecks-smartd.sh
