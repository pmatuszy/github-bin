#!/bin/bash

# 2022.04.30 - v. 0.2 - added healthcheck support
# 2021.02.24 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

echo
m=$( /sbin/fstrim  --verbose --all 2>&1)

if [ -f "$HEALTHCHECKS_FILE" ];then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

echo
. /root/bin/_script_footer.sh

exit

0 */4 * * *     /root/bin/ssd-trim.sh
#0 6-22/4 * * *     /root/bin/ssd-trim.sh 2>&1 > /dev/null
#0 2      * * 0,2-6 /root/bin/ssd-trim.sh 2>&1 > /dev/null
#0 2      * * 1     /root/bin/ssd-trim.sh | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "ssd-trim.sh@`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`" matuszyk+`/bin/hostname`@matuszyk.com
~

