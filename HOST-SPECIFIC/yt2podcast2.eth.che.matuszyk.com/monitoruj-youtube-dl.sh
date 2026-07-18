#!/bin/bash
# v. 20260718.082500 - translate remaining Polish runtime messages to English

# 2026.07.18 - v. 1.9 - translate remaining Polish runtime messages to English
# (C) Paul G. Matuszyk 2020.04.20
# first production version
# 2026.03.24 - v. 1.8 - if log files don't exist, we pause for a couple of seconds
# 2024.09.05 - v. 1.7 - added handling when yt prints "Sign in to confirm you.*re not a bot"
# 2023.02.28 - v. 1.6 - changed grep line format after podsync upgrade changed the message...
#                       added _script_header and _script_footer calls
# v. 1.5 - 2022.02.10 - lowered sleep_dynamic_delay from 0.2 to 0.1
# v. 1.4 - 2021.01.29 - added log_glob and ffmpeg_path instead of absolute paths 
# v. 1.3 - 2020.09.14 - nice tiles for screen session
# v. 1.2 - 2020.04.26 - if too many errors don't wait to the next full minute but initiate the restart
#                       this way we don't exaust our Youtube quota 
#                       added # of errors in the logfile 
#                       du sometimes ended with error on stdout --> should be fixed now
# v. 1.2 - 2020.06.11 - added wolne kb and % of free space
# v. 1.1 - 2020.04.21 - added feature that not restart is done until all ffmpeg processes are gone...
# v. 1.0 - 2020.04.20 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

(C) Paul G. Matuszyk 2020.04.20

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) break ;;
  esac
done

send_email=0
delay_sec=120
delay_first_run=0.1
max_error_lines=1
sleep_dynamic_delay=0.4
log_glob='/home/podsync/logs/podsync-*.log'

ffmpeg_path=/usr/bin/ffmpeg

shopt -s nullglob


tcScrTitleStart="\ek"
tcScrTitleEnd="\e\134"
echo -ne "$tcScrTitleStart $0 $tcScrTitleEnd"

first_run=1
echo "[`date '+%Y.%m.%d %H:%M:%S'`] starting (delay=$delay_sec, max_lines=$max_error_lines)"
pop=`( du -ks /podsync-hdd |awk '{print $1}' ) 2>/dev/null`
echo "[`date '+%Y.%m.%d %H:%M:%S'`] entering infinite loop"

if [ $send_email -ne 0 ] ; then  
  echo Manually restarting podsync feeds | mutt -s "[ `hostname` ] manual podsync restart (`date '+%Y.%m.%d %H:%M:%S'`)" `hostname`@matuszyk.com
fi

while : ; do

  while : ; do
    logi=( ${log_glob} )
    if [ ${#logi[@]} -gt 0 ] ; then
      break
    fi
    echo "[`date '+%Y.%m.%d %H:%M:%S'`] no log files (${log_glob}) - sleeping 10s"
    sleep 10
  done

  # tutaj juz na pewno sa logi
  # dalsza logika...

  if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -gt $max_error_lines ] ; then
     echo '#####################################################################################################'
     echo '#####################################################################################################'
     echo '###################################### RESTART ######################################################'
     echo '#####################################################################################################'
     echo '#####################################################################################################'
     echo 
     echo "[`date '+%Y.%m.%d %H:%M:%S'`] too many error lines in logs — restarting"
     echo "                      error lines in logs: "`egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l`
     if [ $send_email -ne 0 ] ; then
       echo restarting podsync feeds | mutt -s "[ `hostname` ] podsync restart (`date '+%Y.%m.%d %H:%M:%S'`)" `hostname`@matuszyk.com
     fi


     if (( `pgrep -fc ${ffmpeg_path}` >  0 )) ; then
        echo "background ffmpeg count: `pgrep -fc ${ffmpeg_path}` ==> waiting for them to finish..."
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
     echo -n "waiting 20s after restart "
     for p in {1..20};do 
       echo -n .
       sleep 1
     done
     echo
     if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -gt $max_error_lines ] ; then
        echo "still connection problems after restart ==> initiating new restart"
        echo "still connection problems after restart ==> initiating new restart"
        echo "still connection problems after restart ==> initiating new restart"
        continue
     fi
  else
     if [ $first_run -ne 1 ] ; then
       while : ;  do
         if [ `date '+%S'` -eq 0 ] ;then
           break
         else
           sleep $sleep_dynamic_delay
           echo -en "\r[`date '+%Y.%m.%d %H:%M:%S'`] (error lines in logs: `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l`)"
           if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -gt $max_error_lines ] ; then
             echo " (too many lines; max allowed is $max_error_lines) ==> initiating new restart"
             break
           fi
         fi
       done
       echo -en '\r'
     fi
     # w tym miejscu jestesmy jak sie liczba sekund jest zero 

     nast=`( du -ks /podsync-hdd |awk '{print $1}' ) 2>/dev/null`
     delta_kb=`echo ${nast}-${pop}|bc`

     was_used_kb=`LC_NUMERIC=en_US printf "%'.f\n" ${pop}`
     is_used_kb=`LC_NUMERIC=en_US printf "%'.f\n" $nast`
     free_kb=`/bin/df --output=avail /podsync-hdd|tail -1`
     free_kb=`LC_NUMERIC=en_US printf "%'.f\n" $free_kb`
     free_pct=`/bin/df --output=pcent /podsync-hdd|tail -1`
     
     if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -le $max_error_lines ] ; then
       echo -n "[`date '+%Y.%m.%d %H:%M:%S'`] Running. "
       echo -n "# error lines in logs: `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l`"
       echo -n ". Added `echo $delta_kb|awk '{printf "%7.0f\n",$1}'` kB on /podsync-hdd (was used: "$was_used_kb kB", now used: $is_used_kb kB, free kB: $free_kb,${free_pct}). "
     fi
     pop=$nast
     if [ $first_run -eq 1 ] ; then   # first run: do not wait long for second screen line - shown at next full minute
        echo "Waiting until full minute."
        sleep $delay_first_run 
        first_run=0
     else
       if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -le $max_error_lines ] ; then
         echo "Waiting for full minute (${delay_sec}s)."
       fi
      iteration_count=`echo "(${delay_sec}-50)/$sleep_dynamic_delay"| bc` # wait so we do not skip the next full minute ... ;-)
       for (( c=0; c<$iteration_count; c++ )); do
         echo -en "\r[`date '+%Y.%m.%d %H:%M:%S'`] (error lines in logs: `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l`)"
         if [ `egrep "server responded with a 'Too Many Requests' error|Sign in to confirm you.*re not a bot" ${log_glob}|wc -l` -gt $max_error_lines ] ; then
           echo " (too many lines; max allowed is $max_error_lines) ==> initiating new restart"
           break
         fi
         sleep $sleep_dynamic_delay
       done
       echo -en '\r'
     fi
  fi
done

. /root/bin/_script_footer.sh
