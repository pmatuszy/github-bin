#!/bin/bash
# 2022.12.14 - v. 0.1 - initial release (date unknown)

export SKAD="https://www.youtube.com/watch?v=e2gC37ILQmk"
export DOKAD_PREFIX="/worek-samba/nagrania/Kijow-webcamy"

wlasciciel_pliku="che:che"

while : ; do 
  nazwa_pliku="$Kijow-livecam_$(date '+%Y%m%d_%H%M%S').mp4"
  /usr/local/bin/youtube-dl -hide_banner --ignore-errors --no-part --output "${DOKAD_PREFIX}/${nazwa_pliku}" $url 
  chown "${wlasciciel_pliku}" "${DOKAD_PREFIX}/${nazwa_pliku}" 2>/dev/null
  (echo "koniec wykonywania $0" && ls -lr `dirname "${DOKAD_PREFIX}"`) | strings | aha | \
      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
  sleep 5 
done
