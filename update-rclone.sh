#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2026.04.21 - v. 0.6 - after failed selfupdate retries, exit with last rclone rc (not sleep's 0); comment crontab example; tighten up-to-date grep
# 2023.12.18 - v. 0.5 - bugfix: check if rclone is installed
# 2023.03.26 - v. 0.4 - added ile_prob i odstepy_miedzy_probami_sek
# 2023.01.03 - v. 0.3 - added random delay when script runs non-interactively
# 2022.05.20 - v. 0.2 - added printing of current date
# 2022.05.11 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Nie sprawdzamy czy rclone jest uruchomiony — np. rclone mount jest ciagle aktywny; selfupdate i tak wykonujemy.

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

export ile_prob=10
export odstepy_miedzy_probami_sek=20

export RCLONE_BIN=$(type -fP rclone)

if [ -z "${RCLONE_BIN}" ] ; then
  m=$(
    echo '#####################################################'
    echo '#####################################################'
    echo
    echo "rclone is not installed"
    echo
    echo '#####################################################'
    echo '#####################################################'
    )
  if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  fi
  exit 8
fi

# Nie sprawdzamy czy rclone jest uruchomiony — np. rclone mount jest ciagle aktywny; selfupdate i tak wykonujemy.

# if pgrep -f "${RCLONE_BIN}" > /dev/null ; then
#   m=$(
#   echo '#####################################################'
#   echo '#####################################################'
#   echo
#   echo "${RCLONE_BIN} is already running, not starting a new instance; exiting script"
#   echo
#   echo '#####################################################'
#   echo '#####################################################' )
#   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
#   exit 1
# fi

wersja_przed=$(echo " " ; echo " " ; echo "wersja przed: " ; "${RCLONE_BIN}" version 2>&1; echo " " )
wersja_przed_short=$(echo " " ; echo " " ; echo "wersja: " ; "${RCLONE_BIN}" version|head -n 1 2>&1; echo " " )
m=$( echo " "; echo "current date: `date '+%Y.%m.%d %H:%M'`" ; echo ;
     last_rc=1
     for (( p=1 ; p<=$ile_prob;p++)) ;do
       "${RCLONE_BIN}" selfupdate 2>&1
       last_rc=$?
       if (( last_rc == 0 )); then
         echo "Update done with no problems"
         exit 0
       else
         echo "$(date '+%Y.%m.%d %H:%M') Update unsuccessful - retrying in $odstepy_miedzy_probami_sek seconds)"
         sleep $odstepy_miedzy_probami_sek
       fi
     done
     exit "$last_rc"
   )
return_code=$?

wiadomosc=""
if echo "$m" | grep -q "NOTICE: rclone is up to date"; then
  wiadomosc=$(echo "$m" | grep "NOTICE: rclone is up to date" ; "${RCLONE_BIN}" version|head -n 1)
else
  wersja_po=$(echo " " ; echo "wersja po: "; "${RCLONE_BIN}" version 2>&1; echo " " ; echo " ")
  wiadomosc="$m $wersja_przed $wersja_po"
fi

if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit ${return_code}
#####
# new crontab entry (example — install with crontab -e, not as shell):
#
# 5 20 * * * /root/bin/update-rclone.sh
