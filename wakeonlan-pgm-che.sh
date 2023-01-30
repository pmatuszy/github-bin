#!/bin/bash

# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

opoznienie=10

for p in {1..3};do 
  wakeonlan -i 192.168.200.255 04:D9:F5:60:42:4A
  echo opoznienie $opoznienie
  sleep $opoznienie
done

. /root/bin/_script_footer.sh
