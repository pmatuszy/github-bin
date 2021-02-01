# 2021.02.02 - v. 0.4 - added call for script header and footer
# 2021.01.17 - v. 0.3 - changed from inotifywait to md5sum change detection
# 2021.01.13 - v. 0.2 - added "-e attrib" to inotifywait 
# 2020.12.03 - v. 0.1 - initial release, program nie generuje zadnego output na ekran.

. /root/_script_header.sh

plik=/etc/lighttpd/lighttpd.conf
plik_template=/etc/lighttpd/lighttpd.conf.dobry-dziala
md5_template=bd89b2e88bc14e61b9232829bd53fa8d

opoznienie=300    # opoznienie w sekundach po ktorych dopiero odwracamy zmiane pliku (by np. update skonczyl sie)
                  # bylo 120s ale chyba to za malo bo 2x skrypt wyslal maila w dniu 20.01.2021
co_ile_spr=10

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

while : ; do
    #inotifywait -q -e modify -e delete -e close_write -e moved_to -e moved_from -e move -e create -e delete_self -e attrib ${plik}
    if [[ $(md5sum "$plik"|awk '{print $1}') != ${md5_template} ]]; then 
      echo `date`" - wykrylem zmiany w pliku - wysylam maila"
      sleep $opoznienie
      cp ${plik_template} ${plik}
      systemctl restart lighttpd 
      echo "$tresc_maila" | strings | /usr/bin/mailx -s " ( `hostname` - `date '+%Y.%m.%d %H:%M:%S'` ) modifykacja pliku ${plik} zostala odwrocona" matuszyk+`hostname`@matuszyk.com
    else
       sleep $co_ile_spr
    fi
done

. /root/_script_footer.sh
