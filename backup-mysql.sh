#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.06.15 - changed date format
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.03.12 - v. 0.2 - added chmod command to limit backup visibility
# 2022.12.20 - v. 0.1 - initial release

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export BACKUP_DESTINATION=${BACKUP_DESTINATION:-"/var/www/$(date '+%Y%m%d_%H%M%S')_cron_mysqldump-all-databases.sql.pbz2"}
export MYSQL_USER=${MYSQL_USER:-root}
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}
export LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST=100

SCRIPT_VERSION=$(echo ; cat $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; 
                 echo " "; echo "current date: `date '+%Y.%m.%d %H:%M'`" ; echo ;
                 echo "script is run on `hostname`" ; echo
                 )

/usr/bin/mysqlshow -u "${MYSQL_USER}" > /dev/null 2>&1
if (( $? != 0 )); then
   m="echo "${SCRIPT_VERSION}";echo ; I can't connect to MySQL server using mysqlshow "
   wiadomosc=$(echo -e "$SCRIPT_VERSION\n\n$m")
   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
   exit 2
fi
m=$( echo "${SCRIPT_VERSION}";echo ; { /usr/bin/nice -19 /usr/bin/mysqldump -u ${MYSQL_USER} --verbose --all-databases | /usr/bin/nice -19 /usr/bin/pbzip2 -9qc -p2 > "${BACKUP_DESTINATION}" ; } 2>&1 ; exit $?)
return_code=$?

chmod 600 ${BACKUP_DESTINATION}

WHAT_DATABASES_WE_HAVE=$(/usr/bin/mysqlshow -u "${MYSQL_USER}")
OUTPUT_FILE=$(ls -ltr ${BACKUP_DESTINATION})
LAST_BACKUP_FILES=$(ls -l $(dirname ${BACKUP_DESTINATION}) | tail -n $LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST)
wiadomosc=$(echo -e "$SCRIPT_VERSION\n\n$WHAT_DATABASES_WE_HAVE\n\n$m\n\n$OUTPUT_FILE\n\nLAST $LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST BACKUP FILES:\n$LAST_BACKUP_FILES")

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

exit $?
#####
# new crontab entry

0 * * * * /root/bin/backup-mysql.sh
