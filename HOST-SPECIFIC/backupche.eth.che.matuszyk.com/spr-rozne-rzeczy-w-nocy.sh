#!/bin/bash
# 2022.03.29 - v. 0.2 - zmiana na krotsze nazwy skrypow bo screen sobie z dlugimi nie radzi, skrocony czas miedzy wywolaniami screena z 4m do 45s
# 2022.03.05 - v. 0.1 - initial release (date unknown)

odstep_miedzy_wywolaniami=45s

for p in /root/bin/spr-deal-of-the-day-digitec.sh \
         /root/bin/spr-deal-of-the-day-galaxus.sh \
         /root/bin/spr-WD-GOLD-16TB-digitec.sh \
         /root/bin/spr-gopro10.sh \
         /root/bin/spr-GPSMAP-66.sh \
         /root/bin/spr-nuci7.sh \
         /root/bin/spr-nuci7b.sh \
         /root/bin/spr-nucvm.sh \
         /root/bin/spr-fenix.sh \
         /root/bin/spr-seagate-exos.sh \
         /root/bin/spr-veracrypt.sh 


#         /root/bin/spr-gopro4.sh \
#         /root/bin/spr-gopro7.sh \

  do
  /usr/bin/screen -c /dev/null -dmS "$(basename $p)" "$p"
  sleep ${odstep_miedzy_wywolaniami}
done
