#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.07.31 - v. 0.3 - bugfix: better error handling (cd command, find command)
# 2023.04.11 - v. 0.2 - added printing script name
# 2023.02.14 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

new crontab entry

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
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

export DIR=/mnt/luks-raid1-16tb_another/samba/worek-samba/nagrania/Kijow-webcamy
export jak_nowe_pliki_min=2
export maska_plikow='Kijow-livecam_*.mp4'

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

ile_plikow=$(find "${DIR}" -type f -name "${maska_plikow}" -mmin -${jak_nowe_pliki_min} 2>/dev/null | wc -l)

HC_message=$(
   echo "script name: $0"
   echo "current date: `date '+%Y.%m.%d %H:%M'`" ; 
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ;
   echo "katalog: $DIR" ;echo 
   cd "${DIR}" 2>/dev/null

   if (( $? != 0 ));then
     echo "(PGM) Cannot change directory to ${DIR} - filesystem may not be mounted? ABORTING"
     exit 1
   fi
   
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
