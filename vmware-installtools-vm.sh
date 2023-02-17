#!/bin/bash

# 2023.02.17 - v. 0.1 - initial release

. /root/bin/_script_header.sh

mount /dev/cdrom /mnt || exit 2

(
rm /tmp/VMwareTools-* 2>/dev/null
cp -fv /mnt/VMwareTools-* /tmp
cd /tmp ; tar xzvf VMwareTools-*
rm /tmp/VMwareTools-* 2>/dev/null
)
umount /mnt
cd /tmp/vmware-tools-distrib

if (( $# != 0 )) && [ "${1-xxx}" == "manual" ]; then
  echo ; echo "(PGM) enabling manual mode"
  ./vmware-install.pl 
else
  ./vmware-install.pl --default
fi

. /root/bin/_script_footer.sh
