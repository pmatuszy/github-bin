#!/bin/bash

# 2023.07.17 - v. 0.7 - rsync error stream redirecion to stdout
# 2023.07.06 - v. 0.3 - added --no-motd
# 2023.06.25 - v. 0.2 - added optional parameter $3 e.g. --remove-source-files which will be passed to rsync as a parameter
# 2023.03.13 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ ! -z "${HEALTHCHECKS_FORCE_ID:-}" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^$HEALTHCHECKS_FORCE_ID"|awk '{print $2}')
fi

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

check_if_installed curl
check_if_installed rsync
check_if_installed scp openssh-client

RSYNC_BIN="$(type -Pf rsync)"

if (( $# != 2 ))  && (( $# != 3 )) ; then
  echo ; echo "(PGM) wrong # of command line arguments... (must be 2 or 3)" ; echo 
  exit 1
fi

if [ ! -d "${2}" ];then
  echo ; echo "(PGM) Directory ${2} doesn't exist..." ; echo
  exit 2
fi

export rsync_extra_option=""
if (( $# == 3 )) ; then
  "${RSYNC_BIN}" --help | grep -- "$3" >/dev/null 2>&1
  if (( $? != 0 ));then
    echo ; echo "(PGM) Unknown rsync parameter passed as 3rd parameter of the script ($3) ..." ; echo
    echo "(PGM) Unknown rsync parameter passed as 3rd parameter of the script ($3) ..." | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$kod_powrotu 2>/dev/null
    exit 4
  fi
  export rsync_extra_option="${3}"
fi

export SKAD=$1
export DOKAD="$2"

#### export rsync_option="-a -v --stats --bwlimit=990000 --no-compress --progress --info=progress1 --partial  --inplace --remove-source-files"

export rsync_options="--no-motd -a -v --stats --bwlimit=990000 --no-compress --partial  --inplace  -e 'ssh -T -o Compression=no -x -o LogLevel=error ' ${rsync_extra_option}"

HC_MESSAGE=$(
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
   echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;
   
   echo ; echo  ; echo "SKAD  = $SKAD" ; echo "DOKAD = $DOKAD" ; echo 
   echo ; echo "command to be run:"
   echo rsync $rsync_options ${SKAD} "${DOKAD}"
   eval "${RSYNC_BIN}" $rsync_options ${SKAD} "${DOKAD}" 2>&1
   exit $?
   )
kod_powrotu=$?

if (( $script_is_run_interactively == 1 )); then
  echo "$HC_MESSAGE"
  echo "kod_powrotu = $kod_powrotu"
fi

echo "$HC_MESSAGE" | egrep -q "^Number of files: 0$"
kod_1=$?

echo "$HC_MESSAGE" | egrep -q "^Number of created files: 0$"
kod_2=$?

echo "$HC_MESSAGE" | egrep -q "^Number of regular files transferred: 0$"
kod_3=$?

# if rsync exit code is 23 and no files are transferred / created  we treat it as successful run
if (( $kod_powrotu == 23 )) && (( $kod_1 == 0 )) &&  (( $kod_2 == 0 )) && (( $kod_3 == 0 )) ;then
  # we do nothing here - we don't even run curl - if nothing was fetched we do not provide status (neither ok nor error)
  echo > /dev/null
else
  echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$kod_powrotu 2>/dev/null
fi

exit $?
