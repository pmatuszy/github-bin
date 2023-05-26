#!/bin/bash

# 2023.05.26 - v. 0.2 - sending statuses to healthcheck servers before executing exit
# 2023.03.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ ! -z "${HEALTHCHECKS_FORCE_ID:-}" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^$HEALTHCHECKS_FORCE_ID"|awk '{print $2}')
fi

check_if_installed pip python3-pip
check_if_installed curl

if (( $# < 2 )) ; then
  if (( $script_is_run_interactively == 1 )); then
    echo ; echo "(PGM) wrong # of command line arguments... (must be more than 1)" ; echo 
  fi
  echo "(PGM) wrong # of command line arguments... (must be more than 1)" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 1
fi

if [ ! -d "${@:$#}" ];then
  if (( $script_is_run_interactively == 1 )); then
    echo ; echo "(PGM) Directory ${@:$#} doesn't exist..." ; echo
  fi
  echo "(PGM) Directory ${@:$#} doesn't exist..." | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 2
fi

CMD=$(type -fP rotate-backups )

if [ ! $? ] ; then     # if binary can't be found we do not continue
  if (( $script_is_run_interactively == 1 )); then
    echo ; echo "rotate-backups can't be located...";echo
  fi
  echo "rotate-backups can't be located..." | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit 3
fi

TEMP_MESSAGE=$(
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
   echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;

   echo "Numbers of files to be preserved : PRESERVED_PLACEMARK"
   echo "Numbers of files to be deleted   : DELETED_PLACEMARK"
   echo $* | grep -qi -- "--dry-run"
   if (( $? == 0 ));then
     echo "dry run: ON"  | boxes -s 50x3 -a c -d ada-box
   else
     echo "dry run: OFF" | boxes -s 50x3 -a c -d ada-box
   fi
   echo ; echo "command to be run:"
   echo $CMD $*  2>&1 |sed 's|^.* INFO ||g' ; echo 
        $CMD $*  2>&1 |sed 's|^.* INFO ||g' | sed "s|"${@:$#}"/||g" 
   exit $?
   )

kod_powrotu=$?
export number_of_spared_files=$(echo "$TEMP_MESSAGE" | egrep "^Preserving "| wc -l)
export number_of_deleted_filed=$(echo "$TEMP_MESSAGE" | egrep "^Deleting "  | wc -l)

HC_MESSAGE=$(echo "$TEMP_MESSAGE" | sed "s|PRESERVED_PLACEMARK|$number_of_spared_files|g" | sed "s|DELETED_PLACEMARK|$number_of_deleted_filed|g")

if (( $script_is_run_interactively == 1 )); then
  echo "$HC_MESSAGE"
fi

echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$kod_powrotu 2>/dev/null

exit $?
