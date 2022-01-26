#!/bin/bash
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

# SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
SKAD="http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3"
DOKAD_PREFIX="/worek-samba/nagrania/TokFM-nagrania/tokFM"

wlasciciel_pliku="che:che"

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))

while (( $secs_to_midnight > 200 )) ; do
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  let secs_nagrywania=secs_to_midnight+60
  echo $secs_to_midnight $secs_nagrywania
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD"
  kod_powrotu=$?
  chown "${wlasciciel_pliku}" "${DOKAD}"
  if (( $kod_powrotu == 0 ));then
    break
  fi
done

if [ ! -z $STY ]; then    # checking if we are running within screen
  (echo "koniec wykonywania $0" && ls -lr `dirname "${DOKAD}"`) | strings | aha | \
      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
fi
