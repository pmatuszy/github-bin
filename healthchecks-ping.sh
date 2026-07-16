#!/bin/bash

# 2026.07.16 - v. 0.3 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2023.01.03 - v. 0.2 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.12 - v. 0.1 - initial release
#
# healthchecks-ping.sh
#
# Simple Healthchecks success ping (keepalive).
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

Send a success ping to Healthchecks (keepalive).
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

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null

. /root/bin/_script_footer.sh

exit $?

######
# template crontab entry:

# @reboot ( sleep 25 && /root/bin/healthchecks-ping.sh --no_startup_delay ) 2>&1

# */5 * * * *   /root/bin/healthchecks-ping.sh --no_startup_delay
