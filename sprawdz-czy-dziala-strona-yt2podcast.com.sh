#!/bin/bash

# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

if [ `wget yt2podcast.com:8080 -qO - |grep .xml|wc -l` -gt 0 ];then 
   # echo dziala strona yt2podcast.com:8080 | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`hostname --short`) OK - strona yt2podcast.com:8080 dziala" matuszyk+`hostname`@matuszyk.com
   /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
else 
   echo "!!! NIE dziala strona yt2podcast.com:8080" | strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`hostname --short`) PROBLEM - strona yt2podcast.com:8080 NIE dziala" matuszyk+`hostname`@matuszyk.com
   /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh
