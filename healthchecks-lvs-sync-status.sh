#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.07.16 - v. 0.7 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2025.11.05 - v. 0.6 - added info about pvs, vgs, lvs
# 2023.11.02 - v. 0.5 - bugfix: if no lvs present no error is returned
# 2023.07.18 - v. 0.4 - bugfix: redirected 2> to stdout
# 2023.02.28 - v. 0.3 - curl with return_code
# 2023.01.03 - v. 0.2 - bug fixed - when no lvs'm the status should be ok
# 2022.12.29 - v. 0.1 - initial release
#
# healthchecks-lvs-sync-status.sh
#
# Check LVM sync_percent; fail when any LV is not 100% synced; report to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Check LVM logical volume sync status; ping Healthchecks with exit code.
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

m=$( echo "${SCRIPT_VERSION}";echo
     ile_vol=$(lvs --noheadings 2>&1 | wc -l)
     if (( $ile_vol == 0 ));then    # if there are no lvs we exit with no error code
       lvs --segments
       exit 0
     fi

     boxes <<< "lvs -o lv_name,sync_percent" ;  echo
     lvs -o lv_name,sync_percent
     echo

     boxes <<< "lvs " ;  echo
     lvs
     echo
     boxes <<< "lvs --segments" ;  echo
     lvs --segments
     echo

     boxes <<< "vgs" ;  echo
     vgs
     echo

     boxes <<< "pvs" ;  echo
     pvs
     echo

     boxes <<< "pvs --segments -v" ;  echo
     pvs --segments -v

     if [ $(lvs -o 'sync_percent' 2>&1 |sort|uniq|grep -v -e '^[[:space:]]*$'| grep -v 100.00|wc -l) -eq 1 ];then
       exit 0
     else
       exit 1
     fi
   )
return_code=$?

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit $return_code
#####
# new crontab entry

# @reboot /root/bin/healthchecks-lvs-sync-status.sh --no_startup_delay

# 0 * * * * /root/bin/healthchecks-lvs-sync-status.sh --no_startup_delay
