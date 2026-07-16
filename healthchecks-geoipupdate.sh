#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.07.16 - v. 0.5 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2023.02.28 - v. 0.4 - curl with return_code
# 2023.01.09 - v. 0.3 - added random delay support
# 2022.08.09 - v. 0.2 - added info about script version to the output 
# 2022.07.04 - v. 0.1 - initial release
#
# healthchecks-geoipupdate.sh
#
# Run geoipupdate -v; report exit code and output to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Run /usr/bin/geoipupdate -v; ping Healthchecks with exit code and output.
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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo "${SCRIPT_VERSION}";echo ;
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     /usr/bin/geoipupdate -v 2>&1; exit $?
   )
return_code=$?

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${return_code}
#####
# new crontab entry

# 5 7 * * * /root/bin/healthchecks-geoipupdate.sh --no_startup_delay
