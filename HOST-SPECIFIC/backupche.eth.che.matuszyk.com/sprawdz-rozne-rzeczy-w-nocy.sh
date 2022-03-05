#!/bin/bash
# 2022.03.05 - v. 0.1 - initial release (date unknown)

odstep_miedzy_wywolaniami=6m

for p in /root/bin/deal-of-the-day-digitec.sh \
         /root/bin/deal-of-the-day-galaxus.sh \
         /root/bin/WD-GOLD-16TB-digitec.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-gopro4.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-gopro7.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-gopro10.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-GPSMAP-66.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-nuci7.sh \
         /root/bin/sprawdz-aktualizacje-firmware-upgrade-check-nucvm.sh \
         /root/bin/sprawdz-aktualizacje-veracrypt.sh 
  do

  /usr/bin/screen -c /dev/null -dmS "$(basename $p)" "$p"
  sleep ${odstep_miedzy_wywolaniami}
done
