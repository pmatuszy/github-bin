#!/bin/bash

# 2023.10.18 - v. 0.4 - check if wake is needed (added ping at the beginning)
# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

opoznienie=2
IP=192.168.200.250
# MAC="D4:BE:D9:5C:57:FC"      # starty lapek Dell
MAC="A0-29-19-CB-37-CF"      # nowy lapek Dell

ping -c 2  -W 2 -b -q "${IP}" >/dev/null

if (( $? == 0 ));then
  echo ; echo "(PGM) Host $IP is already up. No need to start it again...";echo
  exit 0
fi

for p in {1..5};do 
  wakeonlan -i 192.168.200.255 "$MAC"
  echo opoznienie $opoznienie
  sleep $opoznienie
done

ping -c 3 -W 1 $IP

. /root/bin/_script_footer.sh
