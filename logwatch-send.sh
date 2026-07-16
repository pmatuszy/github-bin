#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.02.10 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

new crontab entry

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
    *) break ;;
  esac
done

export mail_subject="(`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`) logwatch"
export mail_recipient=matuszyk+`/bin/hostname`@matuszyk.com
export details_level=${1:-low}
export range="${2:-yesterday}"

{
check_if_installed mailx
check_if_installed strings
check_if_installed aha

/usr/sbin/logwatch --detail "${details_level}" --range="${range}"
} | strings | aha | mailx -a 'Content-Type: text/html' -s "${mail_subject}" "${mail_recipient}"

. /root/bin/_script_footer.sh

exit $?
#####
# new crontab entry

0 5 * * *   /root/bin/logwatch-send.sh      # optional $1 level can be a positive integer, or high, med, low, which correspond to the integers 10, 5, and 0, respectively.
                                            # optional $2 range e.g. "between -7 days and today" or "yesterday and today"
