#!/bin/bash
# 2022.05.10 - v. 0.5 - dodalem obsluge healthchecks
# 2022.02.04 - v. 0.4 - jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - zmiana sprawdzania czy dzialamy interaktywnie
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

# dobre zroda sa tutaj:
# https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3

# SKAD="http://open.live.bbc.co.uk/mediaselector/5/select/version/2.0/mediaset/http-icy-mp3-a/vpid/bbc_radio_fourfm/format/pls.pls"
# SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm?s=1642067029&e=1642081429&h=b27ba5e1db5ba2f56beacf6d37b8abea"

SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm"
DOKAD_PREFIX="/worek-samba/nagrania/BBC4/BBC4"

wlasciciel_pliku="che:che"

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))

while (( $secs_to_midnight > 200 )) ; do
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
  let secs_nagrywania=secs_to_midnight+60
  DOKAD="${DOKAD_PREFIX}-`date '+%Y.%m.%d__%H%M%S'`.mp3"
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 -o /dev/null "$HEALTHCHECK_URL"/start

  m=$( ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD" 2>&1)
# ffmpeg -hide_banner -loglevel quiet -t "${secs_nagrywania}" -i "$SKAD" "$DOKAD"
  kod_powrotu=$?
  chown "${wlasciciel_pliku}" "${DOKAD}"
  if (( $kod_powrotu == 0 ));then
    break
  fi
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail
  sleep 60 # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
done

if [ -z $PS1 ]; then    # checking if we are running interactively
#  (echo "koniec wykonywania $0" && ls -lr `dirname "${DOKAD}"`) | strings | aha | \
#      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
   log=$(echo;echo;echo "koniec wykonywania $0" && ls -lr `dirname "${DOKAD}"`;echo;echo)
    /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$log" --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"
fi
. /root/bin/_script_footer.sh

