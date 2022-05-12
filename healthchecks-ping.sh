#!/bin/bash
# 2022.05.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh
/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
. /root/bin/_script_footer.sh
exit

######
template crontab entry:

* * * * *   sleep $((RANDOM \% 60)) && /root/bin/healthchecks-ping.sh
