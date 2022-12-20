#!/bin/bash
# 2022.12.20 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export BACKUP_DESTINATION=${BACKUP_DESTINATION:-"/var/www/$(date '+%Y.%m.%d_%H%M%S')_cr_mysqldump-all-databases.sql.pbz2"}
export MYSQL_USER=${MYSQL_USER:-root}
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}

tty 2>&1 >/dev/null
if (( $? != 0 )); then      # we set RANDOM_DELAY only when running NOT from terminal
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  sleep $RANDOM_DELAY
fi

/usr/bin/nice -19 /usr/bin/mysqldump -u${MYSQL_USER} --all-databases | /usr/bin/nice -19 /usr/bin/pbzip2 -9qc -p2 > "${BACKUP_DESTINATION}"

exit
#####
# new crontab entry

1 * * * * /root/bin/backup-mysql.sh
