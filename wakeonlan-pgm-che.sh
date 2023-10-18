#!/bin/bash

# 2023.10.18 - v. 0.4 - check if wake is needed (added ping at the beginning)
# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

opoznienie=2
IP=pgm-che.eth.che.matuszyk.com
MAC="04:D9:F5:60:42:4A"

ping -c 2  -W 2 -q "${IP}" >/dev/null

if (( $? == 0 ));then
  echo ; echo "(PGM) Host $IP is already up. No need to start it again...";echo
  exit 0
fi

for p in {1..20};do 
  wakeonlan -i 192.168.200.255 "$MAC"
  echo opoznienie $opoznienie
  sleep $opoznienie
done

ping -c 40 -W 1 $IP

. /root/bin/_script_footer.sh
