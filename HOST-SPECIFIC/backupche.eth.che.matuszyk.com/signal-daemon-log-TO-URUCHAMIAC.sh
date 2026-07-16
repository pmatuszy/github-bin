#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2025.11.03 - v. 0.6 - small change to print the signal-cli version 
# 2024.12.18 - v. 0.5 - changed opoznienie_miedzy_wywolaniami 5 ==> 30
# 2024.04.11 - v. 0.4 - added --dbus as required by a new version of the daemon
# 2023.02.02 - v. 0.3 - added --foreground option to be able to use Ctrl-C 
# 2023.02.01 - v. 0.2 - added restart once a day
# 202x.xx.xx - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

202x.xx.xx - v. 0.1 - initial release (date unknown)

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

czas_startu_skryptu=$(date '+%s')
secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$czas_startu_skryptu)))
let max_timestamp_dzialania_skryptu=$((($(date +%s)+$secs_to_midnight+20)))
opoznienie_miedzy_wywolaniami=30s

echo
boxes <<< "/opt/signal-cli/bin/signal-cli version"
/opt/signal-cli/bin/signal-cli version
echo 

while : ; do
  let secs_nagrywania=secs_to_midnight+60

  echo "[`date '+%Y.%m.%d %H:%M:%S'`] restart signala"
  timeout --foreground --preserve-status --signal=HUP --kill-after=$((secs_nagrywania+120)) $((secs_nagrywania+60)) \
       /opt/signal-cli/bin/signal-cli -u +41763691467 daemon --dbus 2>&1 > /encrypted/root/signal-output-`date '+%Y%m%d__%H_%M_%S'`.log

  sleep $opoznienie_miedzy_wywolaniami # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
done

. /root/bin/_script_footer.sh
