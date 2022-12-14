#!/bin/bash
# 2022.12.14 - v. 0.7 - dodalem zmiena opoznienie_miedzy_wywolaniami zamiast hardcoded 10s
# 2022.05.16 - v. 0.6 - chown redirection to dev null
# 2022.03.11 - v. 0.7 - bug fix DOKAD ==> DOKAD_PREFIX
# 2022.02.27 - v. 0.6 - max czas dzialania to 20s po najblizszej polnocy
# 2022.02.09 - v. 0.5 - zmiany w logice wykrywania czasu nagrywania
# 2022.02.04 - v. 0.4 - jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - zmiana sprawdzania czy dzialamy interaktywnie
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

# SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
export SKAD="http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3"
export DOKAD_PREFIX="/worek-samba/nagrania/TokFM-nagrania/tokFM"

wlasciciel_pliku="che:che"
opoznienie_miedzy_wywolaniami=20s

czas_startu_skryptu=`date '+%s'`

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$czas_startu_skryptu)))
let max_timestamp_dzialania_skryptu=$((($(date +%s)+$secs_to_midnight+20)))

# echo "czas_startu_skryptu        = $czas_startu_skryptu (`date -d @$czas_startu_skryptu`), max_timestamp_dzialania_skryptu = $max_timestamp_dzialania_skryptu (`date -d @$max_timestamp_dzialania_skryptu`), aktualny czas: $(date +%s) (`date`)"

while (( $(date +%s) - $max_timestamp_dzialania_skryptu <= 0 )) ; do      # spr czy akt sekunda jest mniejsza niz max sekunda, kiedy moze dzialas skrypt
  (echo "POCZATEK wykonywania $0" && ls -lr `dirname "${DOKAD_PREFIX}"`) | strings | aha | \
      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
  let secs_nagrywania=secs_to_midnight+60
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  timeout --preserve-status --signal=HUP --kill-after=$((secs_nagrywania+120)) $((secs_nagrywania+60)) ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD"

  chown "${wlasciciel_pliku}" "${DOKAD}" 2>/dev/null
  sleep $opoznienie_miedzy_wywolaniami # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))

done

if [ -z ${STY:-} ]; then    # checking if we are running interactively
  (echo "koniec wykonywania $0" && ls -lr `dirname "${DOKAD_PREFIX}"`) | strings | aha | \
      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
fi

