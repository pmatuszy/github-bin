#!/bin/bash

# 2023.02.02 - v. 0.1 - initial release

. /root/bin/_script_header.sh

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
  if [ ! -z "${TPM_PASS:-}" ];then
    address=$(vmrun -vp "${TPM_PASS}" getGuestIPAddress $p nogui)
  else
    address=$(vmrun getGuestIPAddress $p nogui)
  fi
  if (( $? != 0 )); then
    echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    cos_nie_tak=1
  fi
  if [[ "${address}" =~ "Error" ]];then
    echo "  spr_ip_address(): cos nie tak - wynik: $address"
    cos_nie_tak=1
  else
    echo "IP Address = $address (PGM)"
  fi
}
#########################################################################################################
spr_vmware_tools() {
  if [ ! -z "${TPM_PASS:-}" ];then
    status=$(vmrun -vp "${TPM_PASS}" checkToolsState $p nogui)
  else
    status=$(vmrun checkToolsState $p nogui)
  fi
  if (( $? != 0 )); then
    echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    cos_nie_tak=1
  fi

  if [ "${status}" != "running" ];then
    echo "spr_vmware_tools(): cos nie tak - wynik: $status"
    cos_nie_tak=1
  else
    echo "vmare Tools are running (OK) (PGM)"
  fi
}
#########################################################################################################
#########################################################################################################
#########################################################################################################

export DISPLAY=

m=$(
  cos_nie_tak=0
  cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo
  echo vmrun list | boxes -s 40x5 -a c
  echo;
  vmrun list | grep Total
  vmrun list | grep -v Total | sort
  echo

  export IFS=$'\n'

  for p in `vmrun list|grep vmx|sort`;do
    echo
    echo "* * * checking $p (PGM) * * *" | boxes -s 40x5 -a c
    spr_ip_address   $p
    spr_vmware_tools $p
  done;
  exit $cos_nie_tak
  )

kod_powrotu=$?

if (( $script_is_run_interactively == 1 )); then
  echo "$m"
fi

if [ $kod_powrotu != 0 ];then
  echo "$m" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  echo "$m" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit

#####
# new crontab entry

0 * * * * /root/bin/vmrun-check-status.sh

