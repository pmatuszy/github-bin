#!/bin/bash

# 2023.03.12 - v. 0.2 - added chmod command to limit backup visibility
# 2022.12.20 - v. 0.1 - initial release

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export BACKUP_DESTINATION=${BACKUP_DESTINATION:-"/var/www/$(date '+%Y.%m.%d_%H%M%S')_cron_mysqldump-all-databases.sql.pbz2"}
export MYSQL_USER=${MYSQL_USER:-root}
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}
export LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST=100

SCRIPT_VERSION=$(echo ; cat $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; 
                 echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;
                 echo "script is run on `hostname`" ; echo
                 )

/usr/bin/mysqlshow -u "${MYSQL_USER}" > /dev/null 2>&1
if (( $? != 0 )); then
   m="I can't connect to MySQL server using mysqlshow "
   wiadomosc=$(echo -e "$SCRIPT_VERSION\n\n$m")
   /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
   exit 2
fi
m=$( { /usr/bin/nice -19 /usr/bin/mysqldump -u ${MYSQL_USER} --verbose --all-databases | /usr/bin/nice -19 /usr/bin/pbzip2 -9qc -p2 > "${BACKUP_DESTINATION}" ; } 2>&1 ; exit $?)
kod_powrotu=$?

chmod 600 ${BACKUP_DESTINATION}

WHAT_DATABASES_WE_HAVE=$(/usr/bin/mysqlshow -u "${MYSQL_USER}")
OUTPUT_FILE=$(ls -ltr ${BACKUP_DESTINATION})
LAST_BACKUP_FILES=$(ls -l $(dirname ${BACKUP_DESTINATION}) | tail -n $LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST)
wiadomosc=$(echo -e "$SCRIPT_VERSION\n\n$WHAT_DATABASES_WE_HAVE\n\n$m\n\n$OUTPUT_FILE\n\nLAST $LIMIT_NUMBER_OF_LAST_BACKUPS_TO_LIST BACKUP FILES:\n$LAST_BACKUP_FILES")

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$wiadomosc" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

exit $?
#####
# new crontab entry

0 * * * * /root/bin/backup-mysql.sh
