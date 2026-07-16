#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.02.12 - v. 0.4 - added check for aha, mailutils and check if we are run interactively
# 2023.02.10 - v. 0.3 - added check for smartmontools package
# 2023.02.01 - v. 0.2 - initial release
# 2022.10.11 - v. 0.1 - initial release

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
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

m=$(
  check_if_installed smartctl smartmontools
  check_if_installed aha
  check_if_installed mailx mailutils

  echo
  update-smart-drivedb
  echo
  )

if (( script_is_run_interactively ));then
  echo "$m"
else
  echo "$m" | strings | aha | \
    /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`) /usr/sbin/update-smart-drivedb" matuszyk+`/bin/hostname`@matuszyk.com
fi 

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry

1 0 1 * *    /root/bin/smart-update-db.sh

