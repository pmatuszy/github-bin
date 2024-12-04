#!/bin/bash

# 2024.12.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

opoznienie=2
IP=192.168.1.6
MAC="1C:6F:65:36:04:7D"

ping -c 2  -W 2 -q "${IP}" >/dev/null

if (( $? == 0 ));then
  echo ; echo "(PGM) Host $IP is already up. No need to start it again...";echo
  exit 0
fi

for p in {1..20};do 
  wakeonlan -i 192.168.1.255 "$MAC"
  echo opoznienie $opoznienie
  sleep $opoznienie
done

ping -c 40 -W 1 $IP

. /root/bin/_script_footer.sh
