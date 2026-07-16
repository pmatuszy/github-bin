#!/bin/bash
# 2026.07.16 - v. 0.9 - rename from sprawdz-czy-dziala-strona-yt2podcast.com.sh; add -h/-v/--no_startup_delay
# 2025.07.06 - v. 0.8 - bugfix - how_many_retries was not decremented... so script was running sometimes forever
# 2024.04.02 - v. 0.7 - added timeout command (as curl sometimes doesn't timeout )
# 2023.04.13 - v. 0.6 - added how_many_retries and retry_delay
# 2023.01.17 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.16 - v. 0.3 - commented out sending emails sections
# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release
#
# healthchecks-site-yt2podcast-com-up.sh
#
# HTTP check yt2podcast.com; ping Healthchecks on success or fail.
#

print_version_banner() {
  local ver=unknown date= line title verline width=60
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  title="$(basename "$0")"
  if [[ -n "$date" ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

HTTP check yt2podcast.com; ping Healthchecks on success or fail.
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
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export URL="yt2podcast.com:8080"  ; export URL
blad=1
how_many_retries=10
retry_delay=15

curl_retry=1
curl_retry_delay=3

export timeout=20
export kill_after=30

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  if [ $(/usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout wget $URL -qO - |grep "Directory Listing"|wc -l) -gt 0 ];then
    /usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /usr/bin/curl -fsS -m 100 --retry $curl_retry --retry-delay $curl_retry_delay -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
    blad=0
    break
  else
    sleep $retry_delay
    ((how_many_retries--))
    if (( script_is_run_interactively == 1 ));then
       echo sleeping for $retry_delay
    fi
  fi
done

if (( $blad != 0 ));then
   /usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /usr/bin/curl -fsS -m 100 --retry $how_many_retries  --retry-delay $retry_delay -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry

*/5 * * * *  /usr/bin/flock --nonblock --exclusive /root/bin/healthchecks-site-yt2podcast-com-up.sh -c /root/bin/healthchecks-site-yt2podcast-com-up.sh --no_startup_delay
