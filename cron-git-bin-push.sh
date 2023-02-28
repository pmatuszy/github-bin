#!/bin/bash

# 2023.02.28 - v. 0.2 - curl with kod_powrotu
# 2023.02.17 - v. 0.1 - initial release

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

HC_message=$(/root/github-bin/git-push.sh batch 2>&1 ; exit $?)
kod_powrotu=$?

if (( script_is_run_interactively ));then
   echo "${HC_message}"
fi

echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

exit $kod_powrotu

#####
# new crontab entry

2 7 * * * /root/bin/cron-git-bin-push.sh
