#!/bin/bash

# 2023.02.02 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo ; echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

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

# we set HEALTHCHECK_STATUS initially to OK - if anything goes wrong I will flip it to BAD
export HEALTHCHECK_STATUS=OK

#########################################################################################################
spr_ip_address() {
  if [ ! -z "${TPM_PASS:-}" ];then
    address=$(vmrun -vp "${TPM_PASS}" getGuestIPAddress $p nogui)
  else
    address=$(vmrun getGuestIPAddress $p nogui)
  fi
  if (( $? != 0 )); then
    echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    HEALTHCHECK_STATUS=BAD
  fi
  if [[ "${address}" =~ "Error" ]];then
    echo cos nie tak
    HEALTHCHECK_STATUS=BAD
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
    HEALTHCHECK_STATUS=BAD
  fi

  if [ "${status}" != "running" ];then
    echo cos nie tak
    HEALTHCHECK_STATUS=BAD
  else
    echo "vmare Tools are running (OK) (PGM)"
  fi
}
#########################################################################################################
#########################################################################################################
#########################################################################################################

export DISPLAY=

echo vmrun list | boxes -s 40x5 -a c
echo;
vmrun list
echo

export IFS=$'\n'

for p in `vmrun list|grep vmx`;do
  echo
  echo "* * * checking $p (PGM) * * *"
  spr_ip_address   $p
  spr_vmware_tools $p
  sleep 0.2 ;
done;

if [ "${HEALTHCHECK_STATUS}" = "BAD" ];then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh
