#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.03.07 - v. 0.6 - added check if fstrim is installed
# 2023.02.28 - v. 0.5 - curl with return_code
# 2023.02.16 - v. 0.4 - added script version and current time
# 2023.01.03 - v. 0.3 - added random delay when script runs non-interactively
# 2022.04.30 - v. 0.2 - added healthcheck support
# 2021.02.24 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

template crontab entry:

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

check_if_installed fstrim util-linux

HC_message=$( 
  echo "${SCRIPT_VERSION}" ; echo 
  /sbin/fstrim  --verbose --all 2>&1
  exit $?
  )
return_code=$?

echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${return_code}

######
# template crontab entry:

# @reboot        ( sleep 45 && /root/bin/ssd-trim.sh) 2>&1
# 0 */4 * * *    /root/bin/ssd-trim.sh
