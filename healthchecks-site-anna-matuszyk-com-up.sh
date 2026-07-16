#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 1.1 - rename from sprawdz-czy-dziala-strona-www.anna.matuszyk.com.sh; add -h/-v/--no_startup_delay
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
#
# healthchecks-site-anna-matuszyk-com-up.sh
#
# HTTP check www.anna.matuszyk.com; ping Healthchecks on success or fail.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

HTTP check www.anna.matuszyk.com; ping Healthchecks on success or fail.
Lookup URL in healthchecks-ids.txt by script basename.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done
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
  # Below - that way you treat 23 the same as .success..
  if curl -fsL "$URL" 2>/dev/null | grep -qm1 "In Short" || [[ $? -eq 23 ]]; then
    /usr/bin/timeout --foreground --preserve-status --kill-after="$kill_after" "$timeout" \
      /usr/bin/curl -fsS -m 100 --fail -L -4 --retry "$curl_retry" --retry-delay "$curl_retry_delay" "$HEALTHCHECK_URL" > /dev/null 2>&1
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
*/15 * * * * /usr/bin/flock -n /tmp/healthchecks-site-anna-matuszyk-com-up.lock /root/bin/healthchecks-site-anna-matuszyk-com-up.sh --no_startup_delay

