#!/bin/bash

# 2025.04.28 - v. 0.21- bugfix edition - script was too verbose 
# 2025.04.26 - v. 0.2 - added multiple retries
# 2023.10.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed curl 
check_if_installed aptitude
check_if_installed boxes

blad=1
how_many_retries=10
retry_delay=15
kod_powrotu=xxx

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  m=$( echo "${SCRIPT_VERSION}";echo
     echo $(type -fP aptitude) -y -q --no-gui update | boxes -a c -d stone
          $(type -fP aptitude) -y -q --no-gui update 2>&1
     echo ; echo
     echo $(type -fP aptitude) -y -q --no-gui safe-upgrade | boxes -a c -d stone 
          $(type -fP aptitude) -y -q --no-gui safe-upgrade 2>&1      # "safe-upgrade" will skip kernel updates and distribution upgrades
     exit_code=$?

     echo ; echo
     echo $(type -fP aptitude) -y -q --no-gui autoclean | boxes -a c -d stone 
          $(type -fP aptitude) -y -q --no-gui autoclean 2>&1

    exit $exit_code
    )
  kod_powrotu=$?
  if [ $script_is_run_interactively == 1 ]; then
    echo "$m"
  fi
  if (( $kod_powrotu == 0 ));then
     blad=0
     break
  else
     sleep $retry_delay
  fi
done

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

####################

@reboot ( sleep 10m && /root/bin/healthchecks-aptitude.sh )
2 */6 * * *    /root/bin/healthchecks-aptitude.sh
