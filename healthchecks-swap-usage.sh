#!/bin/bash
# 2022.06.06 - v. 0.2 - zmiana limitu MAX_DOPUSZCZALNA_ZAJETOSC_SWAP 100 ==> 400
# 2022.06.01 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export MAX_DOPUSZCZALNA_ZAJETOSC_SWAP=400     # w MB
export MIN_RAM_FREE=100     # w MB

m=$( echo " "; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ; 
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
     else
       echo "MAX_DOPUSZCZALNA_ZAJETOSC_SWAP ($MAX_DOPUSZCZALNA_ZAJETOSC_SWAP) > ile_zajetego_SWAP ($ile_zajetego_SWAP) wiec nie trzeba nic robic ..."
       printf "ile_wolnego_RAM    = %5d [MiB]\n" $ile_wolnego_RAM
       printf "ile_zajetego_SWAP  = %5d [MiB]\n" $ile_zajetego_SWAP
       printf "czy_jest_wolny_ram = %5d [MiB]\n" $czy_jest_wolny_ram
       exit 0
     fi
    )

kod_powrotu=$?

if [ $kod_powrotu -ne 0 ]; then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
  exit $kod_powrotu # cos poszlo nie tak
else
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh
exit

######
template crontab entry:

@reboot ( sleep 15 && /root/bin/healthchecks-swap-usage.sh) 2>&1

1 */12 * * *  sleep $((RANDOM \% 60)) && /root/bin/healthchecks-swap-usage.sh
