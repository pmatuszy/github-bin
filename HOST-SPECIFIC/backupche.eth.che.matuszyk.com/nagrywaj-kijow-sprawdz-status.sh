#!/bin/bash

# 2023.04.11 - v. 0.2 - added printing script name
# 2023.02.14 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export DIR=/mnt/luks-raid1-16tb_another/samba/worek-samba/nagrania/Kijow-webcamy
export jak_nowe_pliki_min=2
export maska_plikow='Kijow-livecam_*.mp4'

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

ile_plikow=$(find "${DIR}" -type f -name "${maska_plikow}" -mmin -${jak_nowe_pliki_min} | wc -l)

HC_message=$(
   echo "script name: $0"
   echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; 
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ;
   echo "katalog: $DIR" ;echo 
   cd "${DIR}"
   
   echo "Pliki nowsze niz $jak_nowe_pliki_min minuty: ( $(find . -type f -name "${maska_plikow}" -mmin -${jak_nowe_pliki_min} | wc -l) szt.)" \
        | boxes -s 60x5 -a c
   find . -type f -name "${maska_plikow}" -mmin -${jak_nowe_pliki_min} | sort -r
   echo ;
   echo "Pliki starsze niz $jak_nowe_pliki_min minuty: ( $(find . -type f -name "${maska_plikow}" -mmin +${jak_nowe_pliki_min} | wc -l) szt.)" \
        | boxes -s 60x5 -a c
   find . -type f -name "${maska_plikow}" -mmin +${jak_nowe_pliki_min} | sort -r
  )

if (( ${ile_plikow} > 0 ))  ;then
   echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
else
   echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit

#####
# new crontab entry

*/5 * * * *  /root/bin/nagrywaj-kijow-sprawdz-status.sh
