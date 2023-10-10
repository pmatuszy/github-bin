#!/bin/bash

# 2023.10.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed curl 
check_if_installed aptitude
check_if_installed boxes

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     echo $(type -fP aptitude) -y --no-gui update | boxes -a c -d stone
     $(type -fP aptitude) -y --no-gui update 
     echo ; echo
     echo $(type -fP aptitude) -y --no-gui safe-upgrade | boxes -a c -d stone 
     $(type -fP aptitude) -y --no-gui safe-upgrade     # "safe-upgrade" will skip kernel updates and distribution upgrades
    )

kod_powrotu=$?

if [ $script_is_run_interactively == 1 ]; then
  echo "$m"
fi

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

####################

@reboot ( sleep 10m && /root/bin/healthchecks-aptitude.sh )
2 */6 * * *    /root/bin/healthchecks-aptitude.sh
