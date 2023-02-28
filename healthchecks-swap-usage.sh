#!/bin/bash

# 2023.02.28 - v. 0.6 - curl with kod_powrotu
# 2023.01.03 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.07.01 - v. 0.4 - dodalem trimowanie swapa mimo, ze nie przekracza limitu, ale jest mimo wszystko troche juz jego zaalokowanego
#                       w ten sposob swap jest zwalniany ale nie jest generowany alert do healthchecka
# 2022.06.15 - v. 0.3 - zmiana limitu MAX_DOPUSZCZALNA_ZAJETOSC_SWAP 400 ==> 600
# 2022.06.06 - v. 0.2 - zmiana limitu MAX_DOPUSZCZALNA_ZAJETOSC_SWAP 100 ==> 400
# 2022.06.01 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export MAX_DOPUSZCZALNA_ZAJETOSC_SWAP=600     # w MB
export MIN_RAM_FREE=100                       # w MB
export MAX_USED_SWAP_TO_TRIM_ANYWAY=50        # w MB by zrobic trim ale zwrocic status ok a nie fail

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     ile_wolnego_RAM=$(free -m|grep '^Mem:'|awk '{print $7}');
     ile_zajetego_SWAP=$(free -m|grep '^Swap:'|awk '{print $3}');
     let czy_jest_wolny_ram=$ile_wolnego_RAM-$ile_zajetego_SWAP;
     if (( $czy_jest_wolny_ram >= $MIN_RAM_FREE && $ile_zajetego_SWAP > ${MAX_DOPUSZCZALNA_ZAJETOSC_SWAP} ));then
       echo "wymuszam zmniejszenie zajetosci SWAPa,"
       echo "bo MAX_DOPUSZCZALNA_ZAJETOSC_SWAP ($MAX_DOPUSZCZALNA_ZAJETOSC_SWAP) < ile_zajetego_SWAP ($ile_zajetego_SWAP)"
       echo "RAM tez jest wolny ile_wolnego_RAM ($ile_wolnego_RAM) > MIN_RAM_FREE ($MIN_RAM_FREE)"
       echo "~~~~~~~~ PRZED ~~~~~~~~"
       printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
       printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
       printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
       echo

       swapoff -a ; sleep 2; swapon -a 

       ile_wolnego_RAM=$(free -m|grep '^Mem:'|awk '{print $7}');
       ile_zajetego_SWAP=$(free -m|grep '^Swap:'|awk '{print $3}');
       let czy_jest_wolny_ram=$ile_wolnego_RAM-$ile_zajetego_SWAP;

       echo "~~~~~~~~ PO    ~~~~~~~~"
       printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
       printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
       printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
       echo

       exit 1
     else  # nie ma krytycznej sytuacji, sprawdzamy wiec inne kryteria
       if (( $czy_jest_wolny_ram >= $MIN_RAM_FREE && $ile_zajetego_SWAP > $MAX_USED_SWAP_TO_TRIM_ANYWAY )); then
         echo "trimujemy SWAPa bo troche jest zajetego, ale nie przekracza MAX_DOPUSZCZALNA_ZAJETOSC_SWAP ($MAX_DOPUSZCZALNA_ZAJETOSC_SWAP)"
         echo "RAM tez jest wolny ile_wolnego_RAM ($ile_wolnego_RAM) > MIN_RAM_FREE ($MIN_RAM_FREE)"
         echo "~~~~~~~~ PRZED ~~~~~~~~"
         printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
         printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
         printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
         echo

         swapoff -a ; sleep 2; swapon -a

         ile_wolnego_RAM=$(free -m|grep '^Mem:'|awk '{print $7}');
         ile_zajetego_SWAP=$(free -m|grep '^Swap:'|awk '{print $3}');
         let czy_jest_wolny_ram=$ile_wolnego_RAM-$ile_zajetego_SWAP;

         echo "~~~~~~~~ PO    ~~~~~~~~"
         printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
         printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
         printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
         echo
         exit 0

       fi
       echo "MAX_DOPUSZCZALNA_ZAJETOSC_SWAP ($MAX_DOPUSZCZALNA_ZAJETOSC_SWAP) > ile_zajetego_SWAP ($ile_zajetego_SWAP) wiec nie trzeba nic robic ..."
       printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
       printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
       printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
       exit 0
     fi
    )

kod_powrotu=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

######
template crontab entry:

@reboot ( sleep 15 && /root/bin/healthchecks-swap-usage.sh) 2>&1

1 */12 * * *  sleep $((RANDOM \% 60)) && /root/bin/healthchecks-swap-usage.sh
