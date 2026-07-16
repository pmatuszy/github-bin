#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.03.13 - v. 0.1 - initial release

# policy='--dry-run --relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle'
show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

policy='--dry-run --relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle'

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

policy='--relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle'

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-www02 
export katalog=/mnt/luks-buffalo2/_backupy-1dyne_kopie/www02
eval /root/bin/rotate-backups.sh $policy $katalog

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-cloud
export katalog=/mnt/luks-buffalo2/_backupy-1dyne_kopie/cloud-var-www
eval /root/bin/rotate-backups.sh $policy $katalog
