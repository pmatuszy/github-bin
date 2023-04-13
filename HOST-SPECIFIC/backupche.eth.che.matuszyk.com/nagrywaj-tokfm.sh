#!/bin/bash

# 2023.04.11 - v. 0.8 - almost new version of the script (like BBC one)
# 2022.12.14 - v. 0.7 - dodalem zmiena opoznienie_miedzy_wywolaniami zamiast hardcoded 10s
# 2022.05.16 - v. 0.6 - chown redirection to dev null
# 2022.03.11 - v. 0.7 - bug fix DOKAD ==> DOKAD_PREFIX
# 2022.02.27 - v. 0.6 - max czas dzialania to 20s po najblizszej polnocy
# 2022.02.09 - v. 0.5 - zmiany w logice wykrywania czasu nagrywania
# 2022.02.04 - v. 0.4 - jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - zmiana sprawdzania czy dzialamy interaktywnie
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

# SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
export SKAD="http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3"
export DOKAD_PREFIX="/worek-samba/nagrania/TokFM-nagrania/tokFM"

wlasciciel_pliku="che:che"
opoznienie_miedzy_wywolaniami=40s

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))

while (( $secs_to_midnight > 200 )) ; do
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  let secs_nagrywania=secs_to_midnight+60
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"

  ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD" 2>&1
  kod_powrotu=$?
  chown "${wlasciciel_pliku}" "${DOKAD}"
  if (( $kod_powrotu == 0 ));then
    echo "`date '+%Y.%m.%d__%H%M%S'` koniec wykonywania bo kod powrotu jest 0"
    continue
  fi
  sleep ${opoznienie_miedzy_wywolaniami} # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
done

echo koniec skryptu o `date '+%Y.%m.%d__%H%M%S'`
. /root/bin/_script_footer.sh

