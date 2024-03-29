#!/bin/bash

# 2023.10.12 - v. 0.2 - if status is good there is no need to reinstall 
# 2023.09.06 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export SSH_CONN_TIMEOUT=5     # in seconds

check_if_installed curl
check_if_installed virt-what

if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting..."; echo
  exit 1
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrum utility... exiting ..."; echo
  exit 1
fi

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi
#########################################################################################################
#########################################################################################################
#########################################################################################################

export DISPLAY=

check_if_installed ssh openssh-client

if (( $# != 2 )) ; then
  echo ; echo "(PGM) wrong # of command line arguments... (must be exactly 2)" 
  echo "$0 ip_address_of_the_client full_path_to_vmx_file" ; echo
  exit 1
fi

export VM_IP="$1"
export VM_PATH="$2"

if [ ! -f "${VM_PATH}" ];then
  echo ; echo "(PGM) ${VM_PATH} not found... Exiting ..."
  echo "$0 ip_address_of_the_client full_path_to_vmx_file" ; echo
  exit 2
fi

ping -q -W 1 -c 2 -i 1 ${VM_IP} >/dev/null 2>&1 
if (( $? != 0 )) ; then
  echo ; echo "(PGM) Cannot ping ${VM_IP} ... Exiting ..."
  exit 3
fi

{
echo -n "vm ip address (info from vmrun)         : " ;  vmrun getGuestIPAddress "${VM_PATH}"
return_code1=$?
echo -n "vm vmware tools state (info from vmrun) : " ;  vmrun checkToolsState "${VM_PATH}"
return_code2=$?

if (( $return_code1 > 0 )) ||  (( $return_code2 > 0 ));then
  vmrun installtools "${VM_PATH}" >/dev/null & 
else
  echo "(PGM) No need to install vmware tools as the status is good..."
  exit 0
fi
}

{
echo ; echo "Please wait for the script (/root/bin/vmware-installtools-vm.sh) to finish"
echo ; 
ssh -o ConnectTimeout=${SSH_CONN_TIMEOUT}  ${VM_IP} "/root/bin/vmware-installtools-vm.sh" >/dev/null
echo ; echo 
echo -n "vm ip address (info from vmrun)         : " ;  vmrun getGuestIPAddress "${VM_PATH}"
echo -n "vm vmware tools state (info from vmrun) : " ;  vmrun checkToolsState "${VM_PATH}"
echo
}

. /root/bin/_script_footer.sh
