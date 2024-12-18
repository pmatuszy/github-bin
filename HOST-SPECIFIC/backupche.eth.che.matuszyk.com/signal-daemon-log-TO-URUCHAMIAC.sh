#!/bin/bash

# 2024.12.18 - v. 0.5 - changed opoznienie_miedzy_wywolaniami 5 ==> 30
# 2024.04.11 - v. 0.4 - added --dbus as required by a new version of the daemon
# 2023.02.02 - v. 0.3 - added --foreground option to be able to use Ctrl-C 
# 2023.02.01 - v. 0.2 - added restart once a day
# 202x.xx.xx - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

czas_startu_skryptu=$(date '+%s')
secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$czas_startu_skryptu)))
let max_timestamp_dzialania_skryptu=$((($(date +%s)+$secs_to_midnight+20)))
opoznienie_miedzy_wywolaniami=30s

while : ; do
  let secs_nagrywania=secs_to_midnight+60

  echo "[`date '+%Y.%m.%d %H:%M:%S'`] restart signala"
  timeout --foreground --preserve-status --signal=HUP --kill-after=$((secs_nagrywania+120)) $((secs_nagrywania+60)) \
       /opt/signal-cli/bin/signal-cli -u +41763691467 daemon --dbus 2>&1 > /encrypted/root/signal-output-`date '+%Y%m%d__%H_%M_%S'`.log

  sleep $opoznienie_miedzy_wywolaniami # opozniamy bo jak sa problemy z siecia, to by nie startowac od razu z nastepna proba...
  secs_to_midnight=$((($(date -d "tomorrow 00:00" +%s)-$(date +%s))))
done

. /root/bin/_script_footer.sh
