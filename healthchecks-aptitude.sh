#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.07.16 - v. 0.22 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2025.04.28 - v. 0.21- bugfix edition - script was too verbose 
# 2025.04.26 - v. 0.2 - added multiple retries
# 2023.10.10 - v. 0.1 - initial release
#
# healthchecks-aptitude.sh
#
# Run aptitude update/safe-upgrade/autoclean; report exit code to Healthchecks.
#
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Run aptitude update, safe-upgrade, and autoclean; ping Healthchecks with exit code.
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

check_if_installed curl 
check_if_installed aptitude
check_if_installed boxes

blad=1
how_many_retries=10
retry_delay=15
return_code=xxx

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  m=$( echo "${SCRIPT_VERSION}";echo
     echo $(type -fP aptitude) -y -q --no-gui update | boxes -a c -d stone
          $(type -fP aptitude) -y -q --no-gui update 2>&1
     echo ; echo
     echo $(type -fP aptitude) -y -q --no-gui safe-upgrade | boxes -a c -d stone 
          $(type -fP aptitude) -y -q --no-gui safe-upgrade 2>&1      # "safe-upgrade" will skip kernel updates and distribution upgrades
     exit_code=$?

     echo ; echo
     echo $(type -fP aptitude) -y -q --no-gui autoclean | boxes -a c -d stone 
          $(type -fP aptitude) -y -q --no-gui autoclean 2>&1

    exit $exit_code
    )
  return_code=$?
  if [ $script_is_run_interactively == 1 ]; then
    echo "$m"
  fi
  if (( $return_code == 0 ));then
     blad=0
     break
  else
     sleep $retry_delay
  fi
done

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${return_code}

####################

# @reboot ( sleep 10m && /root/bin/healthchecks-aptitude.sh --no_startup_delay )
# 2 */6 * * *    /root/bin/healthchecks-aptitude.sh --no_startup_delay
