#!/bin/bash

# (C) Paul G. Matuszyk 2020.04.20
# first production version
# 2023.02.28 - v. 1.6 - zmiana formatu linii dla grep bo podnioslem wersje podsynca i zmienil sie message...
#                       added _script_header and _script_footer calls
# v. 1.5 - 2022.02.10 - lowered sleep_1dyncze_opoznienie from 0.2 to 0.1
# v. 1.4 - 2021.01.29 - added maska_logow and ffmpeg_path instead of absolute paths 
# v. 1.3 - 2020.09.14 - nice tiles for screen session
# v. 1.2 - 2020.04.26 - if too many errors don't wait to the next full minute but initiate the restart
#                       this way we don't exaust our Youtube quota 
#                       added # of errors in the logfile 
#                       du sometimes ended with error on stdout --> should be fixed now
# v. 1.2 - 2020.06.11 - added wolne kb and % of free space
# v. 1.1 - 2020.04.21 - added feature that not restart is done until all ffmpeg processes are gone...
# v. 1.0 - 2020.04.20 - initial release

. /root/bin/_script_header.sh

czy_wysylac_maile=0
opoznienie=120
opoznienie_1szy_raz=0.1
max_liczba_linii=1
sleep_1dyncze_opoznienie=0.4
maska_logow='/home/podsync/logs/podsync-*.log'

ffmpeg_path=/usr/bin/ffmpeg


tcScrTitleStart="\ek"
tcScrTitleEnd="\e\134"
echo -ne "$tcScrTitleStart $0 $tcScrTitleEnd"

pierwszy_raz=1
echo "[`date '+%Y.%m.%d %H:%M:%S'`] zaczynamy dzialac, opoznienie=$opoznienie , max_liczba_linii=$max_liczba_linii"
pop=`( du -ks /podsync-hdd |awk '{print $1}' ) 2>/dev/null`
echo "[`date '+%Y.%m.%d %H:%M:%S'`] wchodzimy w petle nieskonczona"

if [ $czy_wysylac_maile -ne 0 ] ; then  
  echo Manualnie startuje feedy podsynca | mutt -s "[ `hostname` ] reczny restart podsynca (`date '+%Y.%m.%d %H:%M:%S'`)" `hostname`@matuszyk.com
fi

while : ; do
  if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -gt $max_liczba_linii ] ; then
     echo '#####################################################################################################'
     echo '#####################################################################################################'
     echo '###################################### RESTART ######################################################'
     echo '#####################################################################################################'
     echo '#####################################################################################################'
     echo 
     echo "[`date '+%Y.%m.%d %H:%M:%S'`] liczba linii z bledami, wiec restartniemy sie"
     echo "                      liczba blednych linii w logach to: "`egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l`
     if [ $czy_wysylac_maile -ne 0 ] ; then
       echo restartuje feedy podsynca | mutt -s "[ `hostname` ] restart podsynca (`date '+%Y.%m.%d %H:%M:%S'`)" `hostname`@matuszyk.com
     fi


     if (( `pgrep -fc ${ffmpeg_path}` >  0 )) ; then
        echo "w tle sa ffmpeg szt. `pgrep -fc ${ffmpeg_path}` ==> czekamy, az zakoncza dzialalnosc..."
     fi

     licznik=1
     echo -n "[`date '+%Y.%m.%d %H:%M:%S'`] # of ffmpeg procs: `pgrep -fc ${ffmpeg_path}`,"
     while (( `pgrep -fc ${ffmpeg_path}` >  0 )) ; do  
        if (( $licznik == 20 ));then
           echo
           echo -n "[`date '+%Y.%m.%d %H:%M:%S'`] # of ffmpeg procs: `pgrep -fc ${ffmpeg_path}`,"
           let licznik=1
        else
           echo -n " `pgrep -fc ${ffmpeg_path}`,"
           let licznik=licznik+1
        fi
        sleep 1
     done
     echo
     su podsync -c "/home/podsync/bin/feeds-restart.sh" 
     echo -n "czekamy 20s po restarcie "
     for p in {1..20};do 
       echo -n .
       sleep 1
     done
     echo
     if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -gt $max_liczba_linii ] ; then
        echo "po restarcie dalej sa problemy z podlaczeniem ==> inicjuje nowy restart"
        echo "po restarcie dalej sa problemy z podlaczeniem ==> inicjuje nowy restart"
        echo "po restarcie dalej sa problemy z podlaczeniem ==> inicjuje nowy restart"
        continue
     fi
  else
     if [ $pierwszy_raz -ne 1 ] ; then
       while : ;  do
         if [ `date '+%S'` -eq 0 ] ;then
           break
         else
           sleep $sleep_1dyncze_opoznienie
           echo -en "\r[`date '+%Y.%m.%d %H:%M:%S'`] (liczba bledow w logach: `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l`)"
           if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -gt $max_liczba_linii ] ; then
             echo " (troche za duzo bo max., ktory dopuszczam to $max_liczba_linii) ==> inicjuje nowy restart"
             break
           fi
         fi
       done
       echo -en '\r'
     fi
     # w tym miejscu jestesmy jak sie liczba sekund jest zero 

     nast=`( du -ks /podsync-hdd |awk '{print $1}' ) 2>/dev/null`
     roznica=`echo ${nast}-${pop}|bc`

     bylo_zajete=`eLC_NUMERIC=en_US printf "%'.f\n" ${pop}`
     jest_zajete=`eLC_NUMERIC=en_US printf "%'.f\n" $nast`
     jest_wolne_kb=`/bin/df --output=avail /podsync-hdd|tail -1`
     jest_wolne_kb=`eLC_NUMERIC=en_US printf "%'.f\n" $jest_wolne_kb`
     jest_wolne_pc=`/bin/df --output=pcent /podsync-hdd|tail -1`
     
     if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -le $max_liczba_linii ] ; then
       echo -n "[`date '+%Y.%m.%d %H:%M:%S'`] Dziala. " 
       echo -n "# linii z bledami w logach : `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l`"
       echo -n ". Przybylo `echo $roznica|awk '{printf "%7.0f\n",$1}'` kB w /podsync-hdd (BYLO zajete: "$bylo_zajete kB", JEST zajete: $jest_zajete kB, wolne kB: $jest_wolne_kb,${jest_wolne_pc}). "
     fi
     pop=$nast
     if [ $pierwszy_raz -eq 1 ] ; then   # pierwszy raz nie czekamy dlugo na druga linie wyswietlona na ekranie - bedzie wysw. przy najblizszej pelnej minucie
        echo "Czekam do pelnej min."
        sleep $opoznienie_1szy_raz 
        pierwszy_raz=0
     else
       if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -le $max_liczba_linii ] ; then
         echo "Czekam min. ${opoznienie}s."
       fi
      liczba_iteracji=`echo "(${opoznienie}-50)/$sleep_1dyncze_opoznienie"| bc` # czekamy liczba_iteracji-20s by nie przeskoczyc nastepnej pelnej minuty ... ;-)
       for (( c=0; c<$liczba_iteracji; c++ )); do
         echo -en "\r[`date '+%Y.%m.%d %H:%M:%S'`] (liczba bledow w logach: `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l`)"
         if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm youâ not a bot" ${maska_logow}|wc -l` -gt $max_liczba_linii ] ; then
           echo " (troche za duzo bo max., ktory dopuszczam to $max_liczba_linii) ==> inicjuje nowy restart"
           break
         fi
         sleep $sleep_1dyncze_opoznienie
       done
       echo -en '\r'
     fi
  fi
done

. /root/bin/_script_footer.sh
