# 2020.12.03 - v. 0.1 - initial release, program nie generuje zadnego output na ekran.

plik=/etc/lighttpd/lighttpd.conf
plik_template=/etc/lighttpd/lighttpd.conf.dobry-dziala

opoznienie=120    # opoznienie w sekundach


if [ ! -f ${plik} ]; then
  echo "plik $plik nie istnieje - wychodze...."
  exit 1
fi
if [ ! -f ${plik_template} ]; then
  echo "plik $plik_template nie istnieje - wychodze...."
  exit 2
fi

while : ; do
    inotifywait -q -e modify ${plik}
    sleep $opoznienie
    cp ${plik_template} ${plik}
    systemctl restart lighttpd 
    echo "plik ${plik} zostal zmodyfikowany, ale przywrocilem domyslna konfiguracje, hehe" | strings | /usr/bin/mailx -s " [ `hostname` ] modifykacja pliku ${plik} zostala odwrocona" matuszyk+`hostname`@matuszyk.com
    echo "plik ${plik} zostal zmodyfikowany, ale przywrocilem domyslna konfiguracje, hehe" | strings | /usr/bin/mailx -s " [ `hostname` ] modifykacja pliku ${plik} zostala odwrocona" mike@matuszyk.com
    echo "plik ${plik} zostal zmodyfikowany, ale przywrocilem domyslna konfiguracje, hehe" | strings | /usr/bin/mailx -s " [ `hostname` ] modifykacja pliku ${plik} zostala odwrocona" marcin.kozak@fractum.pl 
done
