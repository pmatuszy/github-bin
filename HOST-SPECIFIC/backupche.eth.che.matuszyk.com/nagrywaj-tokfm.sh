#!/bin/bash

# 2023.07.08 - v. 1.3 - bugfix: forced aktualny dzien to be a number in 10 base
# 2023.05.22 - v. 1.2 - added NO_STARTUP_DELAY parameters to /root/bin/_script_header.sh
# 2023.05.16 - v. 1.1 - bugfix: functional change of the script
# 2023.05.15 - v. 1.0 - bugfix: functional change of the script
# 2023.04.11 - v. 0.9 - bugfix: removed second invocation of /root/bin/_script_header.sh
# 2023.02.14 - v. 0.8 - removed sending of healthchecks status
# 2022.05.23 - v. 0.7 - dodane 2>/dev/null po wywolaniu curl by nie dostawac maili z crona o timeoucie
# 2022.05.16 - v. 0.6 - eliminacja curla by nie startowac "$url/start" 2x, poprawne badanie kodu powrotu ffmpeg przez dodanie exit $?
# 2022.05.10 - v. 0.5 - dodalem obsluge healthchecks
# 2022.02.04 - v. 0.4 - jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - zmiana sprawdzania czy dzialamy interaktywnie
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh NO_STARTUP_DELAY

# SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
SKAD="http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3"
export DOKAD_PREFIX="/worek-samba/nagrania/TokFM-nagrania/tokFM"

log_file=/tmp/`basename $0`_`date '+%Y.%m.%d__%H%M%S'`.log

wlasciciel_pliku="che:che"
opoznienie_miedzy_wywolaniami=60s
ile_wiecej_sek_nagrywac=120
ile_sek_przed_polnoca_nie_nagrywamy_juz=10

dzien_wywolania=$(date '+%d')
aktualny_dzien=$dzien_wywolania

echo "0. `date '+%Y.%m.%d__%H:%M:%S'` dzien_wywolania = $dzien_wywolania , aktualny_dzien = $aktualny_dzien"


secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
echo "1. `date '+%Y.%m.%d__%H:%M:%S'` secs_to_midnight = $secs_to_midnight" | tee -a $log_file

while (( $secs_to_midnight > $ile_sek_przed_polnoca_nie_nagrywamy_juz )) && (( 10#$dzien_wywolania == 10#$aktualny_dzien )); do # 10# forces a number to be in 10 base
                                                                       # without this on the 8th of the month I got this error line 38: ((: 08: value too great for base (error token is "08")
  echo "2. `date '+%Y.%m.%d__%H:%M:%S'` (na poczatku petli) secs_to_midnight = $secs_to_midnight" | tee -a $log_file
  echo "2. `date '+%Y.%m.%d__%H:%M:%S'` dzien_wywolania = $dzien_wywolania , aktualny_dzien = $aktualny_dzien"

  let secs_nagrywania=secs_to_midnight+ile_wiecej_sek_nagrywac
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  echo "linia komend ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i \"$SKAD\" \"$DOKAD\"" | tee -a $log_file
  ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD" 2>&1

  kod_powrotu=$?
  chown "${wlasciciel_pliku}" "${DOKAD}" 2>/dev/null
  echo "`date '+%Y.%m.%d__%H:%M:%S'` kod powrotu to $kod_powrotu" | tee -a $log_file
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  echo "3. `date '+%Y.%m.%d__%H:%M:%S'` (na koncu petli) secs_to_midnight = $secs_to_midnight" | tee -a $log_file
  sleep ${opoznienie_miedzy_wywolaniami} # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
  aktualny_dzien=$(date '+%d')
  echo "4. `date '+%Y.%m.%d__%H:%M:%S'` dzien_wywolania = $dzien_wywolania , aktualny_dzien = $aktualny_dzien"
done

echo "`date '+%Y.%m.%d__%H:%M:%S'` koniec wykonywania $0" | tee -a $log_file
. /root/bin/_script_footer.sh

