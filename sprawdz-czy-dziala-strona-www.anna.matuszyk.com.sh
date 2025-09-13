#!/bin/bash

# 2025.09.12 - v  1.0 - bugfix - added to curl Uses https:// + -L to follow redirects and -4 to avoid IPv6 edge cases.
#                       --fail-with-body ensures non-2xx/3xx responses are treated as errors.
# 2025.07.03 - v  0.9 - bugfix - curl OK removal from output and one more 
# 2025.07.06 - v. 0.8 - bugfix - how_many_retries was not decremented... so script was running sometimes forever
# 2024.04.02 - v. 0.7 - added timeout command (as curl sometimes doesn't timeout )
# 2023.04.13 - v. 0.6 - added how_many_retries and retry_delay
# 2023.01.17 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.16 - v. 0.3 - commented out sending emails sections
# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ]; then
  HEALTHCHECK_URL=$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

export URL="https://www.anna.matuszyk.com"
blad=1
how_many_retries=30
retry_delay=20

curl_retry=3
curl_retry_delay=10

export timeout=20
export kill_after=30

while (( blad != 0 && how_many_retries != 0 )); do
#   if wget -qO - "$URL" | grep -q "In Short"; then
  if curl -fsL "$URL" 2>/dev/null | grep -qm1 "In Short"; then
    /usr/bin/timeout --foreground --preserve-status --kill-after="$kill_after" "$timeout" \
      /usr/bin/curl -fsS -m 100 --fail-with-body -L -4 --retry "$curl_retry" --retry-delay "$curl_retry_delay" "$HEALTHCHECK_URL" > /dev/null 2>&1
    blad=0
    break
  else
    sleep "$retry_delay"
    ((how_many_retries--))
    if (( script_is_run_interactively == 1 )); then
       echo "sleeping for $retry_delay"
    fi
  fi
done

if (( blad != 0 )); then
  /usr/bin/timeout --foreground --preserve-status --kill-after="$kill_after" "$timeout" \
    /usr/bin/curl -fsS -m 100 --retry "$curl_retry" --retry-delay "$curl_retry_delay" "$HEALTHCHECK_URL/fail" > /dev/null 2>&1
fi

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry
# Note: flock should use a lock file, not the script itself.
*/15 * * * * /usr/bin/flock -n /tmp/sprawdz-czy-dziala.lock /root/bin/sprawdz-czy-dziala-strona-www.anna.matuszyk.com.sh

