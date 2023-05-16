#!/bin/bash

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

# dobre zroda sa tutaj:
# https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3

# SKAD="http://open.live.bbc.co.uk/mediaselector/5/select/version/2.0/mediaset/http-icy-mp3-a/vpid/bbc_radio_fourfm/format/pls.pls"
# SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm?s=1642067029&e=1642081429&h=b27ba5e1db5ba2f56beacf6d37b8abea"

. /root/bin/_script_header.sh

SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm"
DOKAD_PREFIX="/worek-samba/nagrania/BBC4/BBC4"

wlasciciel_pliku="che:che"
opoznienie_miedzy_wywolaniami=60s
ile_wiecej_sek_nagrywac=10
ile_sek_przed_polnoca_nie_nagrywamy_juz=600

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
echo "1. secs_to_midnight = $secs_to_midnight"

while (( $secs_to_midnight > $ile_sek_przed_polnoca_nie_nagrywamy_juz )) ; do
  echo "2. (na poczatku petli) secs_to_midnight = $secs_to_midnight"

  let secs_nagrywania=secs_to_midnight+ile_wiecej_sek_nagrywac
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  echo "linia komend ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i \"$SKAD\" \"$DOKAD\""
  ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD" 2>&1

  kod_powrotu=$?
  chown "${wlasciciel_pliku}" "${DOKAD}"
  echo "`date '+%Y.%m.%d__%H%M%S'` kod powrotu to $kod_powrotu"
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  echo "3. (na koncu petli) secs_to_midnight = $secs_to_midnight"
  sleep ${opoznienie_miedzy_wywolaniami} # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
done

echo koniec wykonywania $0
. /root/bin/_script_footer.sh
