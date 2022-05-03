#!/bin/bash
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

# spr. czy dziala vpn
if [ `ps -ef|grep vpnserver | awk '{print $8}'|grep -v grep|uniq|wc -l` -eq 0 ];then 
  (echo "vpn na `hostname` NIE dziala" | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) vpn nie dziala" matuszyk+`/bin/hostname`@matuszyk.com)
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi
