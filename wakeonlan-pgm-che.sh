#!/bin/bash

# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

opoznienie=2

for p in {1..20};do 
  wakeonlan -i 192.168.200.255 04:D9:F5:60:42:4A
  echo opoznienie $opoznienie
  sleep $opoznienie
done

ping -c 40 -W 1 pgm-che.eth.che.matuszyk.com

. /root/bin/_script_footer.sh
