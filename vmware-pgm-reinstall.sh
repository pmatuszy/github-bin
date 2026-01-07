#!/bin/bash

# 2025.10.22 - v. 0.1 - initial release

. /root/bin/_script_header.sh

installer_full_path="/vmware/VMware-Workstation-Full-17.6.4-24832109.x86_64.bundle"
installer_full_path="/vmware/VMware-Workstation-Full-25H2-24995812.x86_64.bundle"

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo 
  exit 1
fi

boxes <<< "vmrun list"
vmrun list

export DISPLAY=
echo ; vmware -v ; echo

export wersja=$(vmware -v|awk '{print $3}')

echo "Do you want to reinstall vmware after the kernel update? [y/N]"
read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
echo
if [ "${p}" != 'y' -o  "${p}" != 'y' ]; then
  echo "no means no - I am exiting..."
  exit 1
fi

type -fP "${installer_full_path}" 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find ${installer_full_path} installer... exiting ..."; echo
  exit 1
fi

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo 

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo

boxes <<< "${installer_full_path} --uninstall-product=vmware-workstation --required  --console"
"${installer_full_path}" --uninstall-product=vmware-workstation --required  --console ; echo

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo

boxes <<< "${installer_full_path} --required --eulas-agreed --console"
"${installer_full_path}" --required --eulas-agreed --console ; echo

boxes <<< "${installer_full_path} --list-products --console"
"${installer_full_path}" --list-products --console ; echo

boxes <<< "${installer_full_path} --list-components --console"
"${installer_full_path}" --list-components --console ; echo


. /root/bin/_script_footer.sh
