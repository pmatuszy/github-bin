#!/bin/bash
# 2022.05.06 - v. 1.4 - added RUN_BEFORE_BACKUP and RUN_AFTER_BACKUP
# 2022.05.06 - v. 1.3 - added check if we are run from CRON
# 2022.05.04 - v. 1.2 - added healthcheck support, remove sensitive data from the script itself
# 2021.04.16 - v. 1.1 - small change to exit message when XDG_CACHE_HOME is not defined
# 2021.04.14 - v. 1.0 - added checks for RESTIC_BIN and XDG_CACHE_HOME, overhauld of the script
# 2021.04.11 - v. 0.2 - added /bin/bash as the first line of the script
# 2021.04.10 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

. "${RESTIC_BACKUP_ENV_FILE}"

RUN_BEFORE_BACKUP=''
RUN_AFTER_BACKUP=''

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^${RESTIC_BACKUP_NAME}"|awk '{print $2}')
fi

if [ -f /encrypted/root/scripts/repo-pass-info.sh ];then
  REPO_PASS_INFO=/encrypted/root/scripts/repo-pass-info.sh
fi

if [ -f /root/repo-pass-info.sh ];then
  REPO_PASS_INFO=/root/repo-pass-info.sh
fi

if [ -f "$REPO_PASS_INFO" ]; then
  . "$REPO_PASS_INFO"
else
  echo '#####################################################'
  echo '#####################################################'
  echo
  echo "${REPO_PASS_INFO} nie moze byc znaleziony. Wychodze"
  echo
  echo '#####################################################'
  echo '#####################################################'
  exit 4
fi

# check if we are run from the cron
CRON=$(pstree -s $$ | grep -q cron && echo true || echo false)

if $CRON ; then
  mail_subject=" ( `/bin/hostname`  - `date '+%Y.%m.%d %H:%M:%S'`) $(basename $0)"
  # mail_adressee=matuszyk+`/bin/hostname`@matuszyk.com
  # exec 2>&1 > >( strings | aha | /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$mail_subject" "$mail_adressee")
fi

if [ ! -f "$RESTIC_BIN" ]; then
  echo '#####################################################'
  echo '#####################################################'
  echo
  echo "restic binary defined as ${RESTIC_BIN} nie moze byc znaleziony. Wychodze"
  echo
  echo '#####################################################'
  echo '#####################################################'
  exit 2
fi

if [ -d "/root/restic-cache-dir" ]; then
  export XDG_CACHE_HOME="/root/restic-cache-dir"
fi

if [ -d "/encrypted/root/restic-cache-dir" ]; then
  export XDG_CACHE_HOME="/encrypted/root/restic-cache-dir"
fi

if [ ! -d "$XDG_CACHE_HOME" ] ; then
   echo "XDG_CACHE_HOME ($XDG_CACHE_HOME)  nie istnieje"
   echo "WYCHODZE ..."
   exit 4
fi

if pgrep -f "${RESTIC_BIN}" > /dev/null ; then
  echo '#####################################################'
  echo '#####################################################'
  echo
  echo "${RESTIC_BIN} dziala, wiec nie startuje nowej instancji a po prostu koncze dzialanie skryptu"
  echo
  echo '#####################################################'
  echo '#####################################################'
  exit 2
fi

if [ ! -d "$XDG_CACHE_HOME" ] ; then
   echo "$XDG_CACHE_HOME nie istnieje"
   echo "WYCHODZE ..."
   exit 1
fi

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null

eval $RUN_BEFORE_BACKUP

backup_log=$( echo ; echo "RESTIC_REPOSITORY = $RESTIC_REPOSITORY" ; echo ;
    eval ${RESTIC_BIN} --cleanup-cache --iexclude=${MY_EXCLUDES} --iexclude-file=${MY_EXCLUDE_FILE} backup / $WHAT_TO_BACKUP_ON_TOP_OF_ROOT )
kod_powrotu=$?

eval $RUN_AFTER_BACKUP

m=$( echo ; echo "~~~~~~~~~~~~~~~~~~~~~~~~~"
     echo kod powrotu z backupu: $kod_powrotu ; echo "~~~~~~~~~~~~~~~~~~~~~~~~~" ; echo ;
     ${RESTIC_BIN} --cleanup-cache                          snapshots 2>&1 )

# by output poszedl mailem...
echo "$backup_log"
echo "###########################################################"
echo "$m"

if (( $kod_powrotu != 0 )); then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$backup_log" --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$backup_log" --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh
