#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2025.10.24 - v. 0.3 - bugfix: "bash: line 1: /usr/bin/rsync: Argument list too long" - in SOURCE is in double quotes and end changed to /* to /
# 2023.12.20 - v. 0.2 - added healthchecks download
# 2023.03.14 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (sciagnij-backupy-nuci7b).

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

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-www02
SOURCE=www02.eth.r.matuszyk.com:/var/www/202*bz2
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/www02

eval /root/bin/sciagnij-backupy.sh "$SOURCE" "$DEST"



export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-cloud
SOURCE=cloud.eth.r.matuszyk.com:/var/www/202*bz2
DEST="/mnt/luks-buffalo2/_backupy-1dyne_kopie/cloud-var-www"

eval /root/bin/sciagnij-backupy.sh "$SOURCE" "$DEST"



export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-lublin-healthchecks-logs
SOURCE="lublin.eth.r.matuszyk.com:/mnt/luks-RaidSonicB/postgres/backup/lublin.eth.r.matuszyk.com/pgbackrest/logs/"
DEST="/mnt/luks-buffalo2/_backupy-1dyne_kopie/postgresql-lublin/healthchecks-pgbackreset-logs/"

eval /root/bin/sciagnij-backupy.sh "$SOURCE" "$DEST"



export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-lublin-healthchecks-backups
SOURCE="lublin.eth.r.matuszyk.com:/mnt/luks-RaidSonicB/postgres/backup/lublin.eth.r.matuszyk.com/pgbackrest/backup/healthchecks/"
DEST="/mnt/luks-buffalo2/_backupy-1dyne_kopie/postgresql-lublin/healthchecks-backupy/"

eval /root/bin/sciagnij-backupy.sh "$SOURCE" "$DEST"
