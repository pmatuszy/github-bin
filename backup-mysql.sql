#!/bin/bash
# 2022.12.20 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh
if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

backup_destination="/var/www/$(date '+\%Y.\%m.\%d_\%H\%M\%S')_cr_mysqldump-all-databases.sql.pbz2"
mysql_user=root

/usr/bin/nice -19 /usr/bin/mysqldump -u${mysql_user} --all-databases | /usr/bin/nice -19 /usr/bin/pbzip2 -9qc -p2 > "${backup_destination}"

exit
#####
# new crontab entry

1 * * * * /root/bin/backup-mysql.sql
