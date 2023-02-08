#!/bin/bash

# 2023.02.08 - v. 0.1 - initial release

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

# spr. czy dziala vpn
if [ `ps -ef|grep vpnserver | awk '{print $8}'|grep -v grep|uniq|wc -l` -eq 0 ];then 
#  (echo "vpn na `hostname` NIE dziala" | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) vpn nie dziala" matuszyk+`/bin/hostname`@matuszyk.com)
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

*/3 * * * * /root/bin/sprawdz-czy-dziala-server-vpn.sh

# old crontab entry
# spr. czy dziala vpn
#5 */6 * * * if [ `ps -ef|grep vpnserver | awk '{print $8}'|grep -v grep|uniq|wc -l` -eq 0 ];then (echo "vpn na `hostname` NIE dziala" | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) vpn nie dziala" matuszyk+`/bin/hostname`@matuszyk.com) ; fi

~

