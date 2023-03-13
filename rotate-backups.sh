#!/bin/bash

# 2023.03.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed pip python3-pip

if (( $# < 2 )) ; then
  echo ; echo "(PGM) wrong # of command line arguments... (must be more than 1)" ; echo 
  exit 1
fi

if [ ! -d "${@:$#}" ];then
  echo ; echo "(PGM) Directory $1 doesn't exist..." ; echo
  exit 2
fi

CMD=$(type -fP rotate-backups )

if [ ! $? ] ; then     # if binary can't be found we do not continue
  echo ; echo "rotate-backups can't be located...";echo
  exit 3
fi

echo $CMD $*
HC_MESSAGE=$($CMD $*  2>&1 |sed 's|^.* INFO ||g' ; exit $?)

echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$? 2>/dev/null

exit $?
#####
# new crontab entry

@reboot ( sleep 3m && /root/bin/rotate-backups.sh )

1 0 * * *    /root/bin/rotate-backups.sh --dry-run --syslog=no --relaxed --hourly=24*2 XXXXXXXXXXXX/XXXXXXXXXX
