#!/bin/bash

# 2023.05.09 - v. 0.7 - added checking if the script is run on the physical machine
# 2023.03.15 - v. 0.6 - bugfix: if ip address is 'unknown' then we raise the error
# 2023.02.28 - v. 0.5 - curl with kod_powrotu
# 2023.02.15 - v. 0.4 - bug fixes for wrong status (was OK instead of PROBLEM)
# 2023.02.06 - v. 0.3 - small bug fix cos_nie_tak=0 after successful run is set now
# 2023.02.05 - v. 0.2 - added how_many_retries retry_delay - sometimes retry helps to check statuses
#                       added printing of the current date and time
# 2023.02.02 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed curl
check_if_installed virt-what

if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

how_many_retries=3
retry_delay=2

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrum utility... exiting ..."; echo
  exit 1
fi

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi
#########################################################################################################
spr_ip_address() {
 
  blad=0

  for ((retry=0 ; retry<$how_many_retries ; retry++));do
    if [ ! -z "${TPM_PASS:-}" ];then
      echo "vmrun -vp ********** getGuestIPAddress $p nogui"
      address=$(vmrun -vp "${TPM_PASS}" getGuestIPAddress $p nogui)
    else
      echo "vmrun getGuestIPAddress $p nogui"
      address=$(vmrun getGuestIPAddress $p nogui)
    fi
    if (( $? != 0 )); then
      echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
      blad=1
    fi
    if [[ "${address}" =~ "Error" ]] || [[ "${address}" =~ "unknown" ]] ;then
      echo "  spr_ip_address(): cos nie tak - wynik: $address"
      blad=1
    else
      echo "IP Address = $address (PGM)"
      return 0
    fi
    sleep $retry_delay
  done
  if (( $blad != 0 ));then
    cos_nie_tak=1
  fi
}
#########################################################################################################
spr_vmware_tools() {
 
  blad=0

  for ((retry=0 ; retry<$how_many_retries ; retry++));do
    if [ ! -z "${TPM_PASS:-}" ];then
      echo "vmrun -vp ********** checkToolsState $p nogui"
      status=$(vmrun -vp "${TPM_PASS}" checkToolsState $p nogui)
    else
      echo "vmrun checkToolsState $p nogui"
      status=$(vmrun checkToolsState $p nogui)
    fi
    if (( $? != 0 )); then
      echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
      blad=1
    fi
    if [ "${status}" != "running" ];then
      echo "spr_vmware_tools(): cos nie tak - wynik: $status"
      blad=1
    else
      echo "vmare Tools are running (OK) (PGM)"
      return 0
    fi
  done
  if (( $blad != 0 ));then
    cos_nie_tak=1
  fi
}
#########################################################################################################
#########################################################################################################
#########################################################################################################

export DISPLAY=

m=$(
  cos_nie_tak=0
  cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo
  echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;
  echo vmrun list | boxes -s 40x5 -a c
  echo;
  vmrun list | grep Total
  vmrun list | grep -v Total | sort
  echo

  export IFS=$'\n'

  for p in `vmrun list|grep vmx|sort`;do
    echo
    echo "checking $p (PGM)" | boxes -s 40x5 -a c
    spr_ip_address   $p
    spr_vmware_tools $p
  done;
  exit $cos_nie_tak
  )

kod_powrotu=$?

if (( $script_is_run_interactively == 1 )); then
  echo "$m"
fi

echo "$m" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

#####
# new crontab entry

0 * * * * /root/bin/vmrun-check-status.sh
