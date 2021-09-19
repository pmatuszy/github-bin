#!/bin/bash

# 2021.09.19 - v. 0.6 - dodalem wypisywanie kropek, by ladniej wygladalo
# 2021.06.17 - v. 0.5 - najpierw jest przeliczana md5 suma pliku plik_template
# 2021.02.02 - v. 0.4 - added call for script header and footer
# 2021.01.17 - v. 0.3 - changed from inotifywait to md5sum change detection
# 2021.01.13 - v. 0.2 - added "-e attrib" to inotifywait 
# 2020.12.03 - v. 0.1 - initial release, program nie generuje zadnego output na ekran.

. /root/bin/_script_header.sh

plik=/etc/lighttpd/lighttpd.conf
plik_template=/etc/lighttpd/lighttpd.conf.dobry-dziala
md5_template=`md5sum /etc/lighttpd/lighttpd.conf.dobry-dziala|awk '{print $1}'`

opoznienie=300    # opoznienie w sekundach po ktorych dopiero odwracamy zmiane pliku (by np. update skonczyl sie)
                  # bylo 120s ale chyba to za malo bo 2x skrypt wyslal maila w dniu 20.01.2021
co_ile_spr=30
co_ile_wypisac_date=200

tresc_maila="plik ${plik} zostal zmodyfikowany, ale przywrocilem domyslna konfiguracje, hehe"

if [ ! -f ${plik} ]; then
  echo "plik $plik nie istnieje - wychodze...."
  exit 1
fi
if [ ! -f ${plik_template} ]; then
  echo "plik $plik_template nie istnieje - wychodze...."
  exit 2
fi

shopt -s nocasematch

licznik=0
echo -n "`date '+%Y.%m.%d %H:%M:%S'` "
while : ; do
    #inotifywait -q -e modify -e delete -e close_write -e moved_to -e moved_from -e move -e create -e delete_self -e attrib ${plik}
    if [[ $(md5sum "$plik"|awk '{print $1}') != ${md5_template} ]]; then 
      echo   #  piszemy pusta linie, bo zwykle ostatnia linia byla bez znaku konca linii
      echo `date '+%Y.%m.%d %H:%M:%S'`" - wykrylem zmiany w pliku - wysylam maila"
      sleep $opoznienie
      cp ${plik_template} ${plik}
      systemctl restart lighttpd 
      echo "$tresc_maila" | strings | /usr/bin/mailx -s "(`hostname`-`date '+%Y.%m.%d %H:%M:%S'`) modifykacja pliku ${plik} zostala odwrocona" matuszyk+`hostname`@matuszyk.com
      let licznik=0
    else
       sleep $co_ile_spr
       echo -n "."
       let licznik=licznik+1
       if (( $licznik == $co_ile_wypisac_date )) ; then
         echo ; echo -n "`date '+%Y.%m.%d %H:%M:%S'` "
         licznik=0
       fi
    fi
done

. /root/bin/_script_footer.sh
