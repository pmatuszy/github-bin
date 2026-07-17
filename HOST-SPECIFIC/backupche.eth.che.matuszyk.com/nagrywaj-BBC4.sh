#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.05.22 - v. 1.2 - added NO_STARTUP_DELAY parameters to /root/bin/_script_header.sh
# 2023.05.16 - v. 1.1 - bugfix: functional change of the script
# 2023.05.15 - v. 1.0 - bugfix: functional change of the script
# 2023.04.11 - v. 0.9 - bugfix: removed second invocation of /root/bin/_script_header.sh
# 2023.02.14 - v. 0.8 - removed sending of healthchecks status
# 2022.05.23 - v. 0.7 - added 2>/dev/null after curl so cron does not mail about timeout
# 2022.05.16 - v. 0.6 - removed curl so we do not start "$url/start" 2x, check ffmpeg exit code correctly via exit $?
# 2022.05.10 - v. 0.5 - added support for healthchecks
# 2022.02.04 - v. 0.4 - if ffmpeg ends early, added 60s delay, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - changed interactive-run detection
# 2022.01.26 - v. 0.2 - if ffmpeg ends early, restart recording until midnight + 1 minute
# 2022.01.13 - v. 0.1 - initial release (date unknown)

# dobre zroda sa tutaj:
# https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3

# SOURCE="http://open.live.bbc.co.uk/mediaselector/5/select/version/2.0/mediaset/http-icy-mp3-a/vpid/bbc_radio_fourfm/format/pls.pls"
# SOURCE="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm?s=1642067029&e=1642081429&h=b27ba5e1db5ba2f56beacf6d37b8abea"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

dobre zroda sa tutaj:

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

. /root/bin/_script_header.sh --no_startup_delay

SOURCE="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm"
DEST_PREFIX="/worek-samba/nagrania/BBC4/BBC4"

# export http_proxy=http://localhost:9080

log_file=/tmp/`basename $0`_`date '+%Y.%m.%d__%H%M%S'`.log

file_owner="che:che"
delay_between_runs=60s
extra_record_seconds=120
seconds_before_midnight_stop=10

invocation_day=$(date '+%d')
current_day=$invocation_day

echo "0. `date '+%Y.%m.%d__%H:%M:%S'` invocation_day = $invocation_day , current_day = $current_day"

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
echo "1. `date '+%Y.%m.%d__%H:%M:%S'` secs_to_midnight = $secs_to_midnight" | tee -a $log_file

while (( $secs_to_midnight > $seconds_before_midnight_stop )) && (( $invocation_day == $current_day )); do
  echo "2. `date '+%Y.%m.%d__%H:%M:%S'` (na poczatku petli) secs_to_midnight = $secs_to_midnight" | tee -a $log_file
  echo "2. `date '+%Y.%m.%d__%H:%M:%S'` invocation_day = $invocation_day , current_day = $current_day"

  let record_seconds=secs_to_midnight+extra_record_seconds
  DEST="${DEST_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  echo "ffmpeg command line -hide_banner -loglevel quiet -t "${record_seconds}" -i \"$SOURCE\" \"$DEST\"" | tee -a $log_file
  ffmpeg -hide_banner -loglevel quiet -t "${record_seconds}" -i "$SOURCE" "$DEST" 2>&1

  return_code=$?
  chown "${file_owner}" "${DEST}" 2>/dev/null
  echo "`date '+%Y.%m.%d__%H:%M:%S'` exit code is $return_code" | tee -a $log_file
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  echo "3. `date '+%Y.%m.%d__%H:%M:%S'` (na koncu petli) secs_to_midnight = $secs_to_midnight" | tee -a $log_file
  sleep ${delay_between_runs} # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
  current_day=$(date '+%d')
  echo "4. `date '+%Y.%m.%d__%H:%M:%S'` invocation_day = $invocation_day , current_day = $current_day"
done

echo "`date '+%Y.%m.%d__%H:%M:%S'` koniec wykonywania $0" | tee -a $log_file
. /root/bin/_script_footer.sh
