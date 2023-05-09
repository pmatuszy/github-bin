#!/bin/bash

# 2023.05.09 - v. 0.4 - added checking if the script is run on the virtual machine
# 2023.03.03 - v. 0.3 - if open-vm-tools is installed we will uninstall it
# 2023.03.03 - v. 0.2 - if cdrom is already mounted under /mnt/tmp we do not remount it again....
# 2023.02.17 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed virt-what
if (( $(virt-what | wc -l) == 0 ));then
  echo ; echo "host is NOT a vm... exiting...";echo
  exit 1
fi

if [ ! -f  /mnt/tmp/vmware-tools-upgrader-64 ];then
  mkdir -p /mnt/tmp
  mount /dev/cdrom /mnt/tmp || exit 2
fi

if [ ! $(dpkg -s open-vm-tools >/dev/null 2>&1 ) ];then    # openvm tools are NOT installed
  echo "usuwam open-vm-tools, bo nie chce uzywac tego pakietu" | boxes -s 50x3 -a c -d ada-box
  echo apt remove -y open-vm-tools | boxes -s 50x3 -a c -d ada-box
  apt remove -y --purge open-vm-tools >/dev/null 2>&1
fi

{
rm /tmp/VMwareTools-* 2>/dev/null
cp -fv /mnt/tmp/VMwareTools-* /tmp
cd /tmp ; tar xzf VMwareTools-*
rm /tmp/VMwareTools-* 2>/dev/null
}

umount /mnt/tmp
cd /tmp/vmware-tools-distrib

if (( $# != 0 )) && [ "${1-xxx}" == "manual" ]; then
  echo ; echo "(PGM) enabling manual mode"
  ./vmware-install.pl 
else
  ./vmware-install.pl --default
fi

. /root/bin/_script_footer.sh
