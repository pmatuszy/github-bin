#!/bin/bash

# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

opoznienie=15

for p in {1..9};do 
  wakeonlan -i 192.168.200.255 04:D9:F5:60:42:4A
  echo opoznienie $opoznienie
  sleep $opoznienie
done

ping -c 20 -W 1 pgm-che.eth.che.matuszyk.com

. /root/bin/_script_footer.sh
