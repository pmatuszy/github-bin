#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 0.5 - rename from sprawdz-czy-encrypted-jest-zamontowany.sh; add -h/-v/--no_startup_delay
# 2023.02.28 - v. 0.4 - curl with return_code
# 2023.01.03 - v. 0.3 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.12 - v. 0.2 - usunieta zmienna m, ktora nie byla uzywana
# 2022.05.03 - v. 0.1 - initial release (date unknown)
#
# healthchecks-encrypted-is-mounted.sh
#
# Check /encrypted mountpoint; ping Healthchecks with mountpoint exit code.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Check /encrypted mountpoint; ping Healthchecks with mountpoint exit code.
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

mountpoint -q /encrypted
return_code=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${return_code}
#####
# new crontab entry

6 * * * * /root/bin/healthchecks-encrypted-is-mounted.sh --no_startup_delay
