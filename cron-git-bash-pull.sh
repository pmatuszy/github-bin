#!/bin/bash

# 2026.06.02 - v. 0.3 - ping Healthchecks only when HEALTHCHECK_URL is set (avoid silent curl to empty URL)
# 2023.02.28 - v. 0.2 - curl with kod_powrotu
# 2023.02.17 - v. 0.1 - initial release

. /root/bin/_script_header.sh
HEALTHCHECK_URL=""
if [[ -f "$HEALTHCHECKS_FILE" ]]; then
  HEALTHCHECK_URL=$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

HC_message=$(/root/github-bash_profile/git-pull.sh batch 2>&1 ; exit $?)
kod_powrotu=$?

if (( script_is_run_interactively ));then
   echo "${HC_message}"
fi

if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
  echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "${HEALTHCHECK_URL}/${kod_powrotu}" 2>/dev/null
fi

exit "${kod_powrotu}"

#####
# new crontab entry

1 7 * * *   /root/bin/cron-git-bash-pull.sh
