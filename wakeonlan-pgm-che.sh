#!/bin/bash

# 2025.04.25 - v. 0.5 - added some cosmetic improvements to the script according to ChatGPT suggestions
# 2023.10.18 - v. 0.4 - check if wake is needed (added ping at the beginning)
# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

delay=2
IP=pgm-che.eth.che.matuszyk.com
MAC="04:D9:F5:60:42:4A"
BROADCAST="192.168.200.255"

ping -c 2  -W 2 -q "${IP}" >/dev/null

if (( $? == 0 ));then
  echo ; echo "(PGM) Host $IP is already up. No need to start it again...";echo
  exit 0
fi

for p in {1..20};do 
  wakeonlan -i "$BROADCAST" "$MAC"
  echo delay $delay
  sleep $delay
done

if ping -c 3 -W 1 "$IP" ; then
  echo "(PGM) Host $IP successfully woke up."
else
  echo "(PGM) Host $IP did not respond after WOL attempts."
fi

logger "WOL script: sent packet to $MAC at $BROADCAST"

. /root/bin/_script_footer.sh
