#!/bin/bash
# 2022.03.05 - v. 0.1 - initial release (date unknown)

odstep_miedzy_wywolaniami=4m

for p in /root/bin/deal-of-the-day-digitec.sh \
         /root/bin/deal-of-the-day-galaxus.sh \
         /root/bin/WD-GOLD-16TB-digitec.sh \
         /root/bin/spr-gopro4.sh \
         /root/bin/spr-gopro7.sh \
         /root/bin/spr-gopro10.sh \
         /root/bin/spr-GPSMAP-66.sh \
         /root/bin/spr-nuci7.sh \
         /root/bin/spr-nucvm.sh \
         /root/bin/sprawdz-aktualizacje-veracrypt.sh 
  do

  /usr/bin/screen -c /dev/null -dmS "$(basename $p)" "$p"
  sleep ${odstep_miedzy_wywolaniami}
done
