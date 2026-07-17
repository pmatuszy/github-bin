#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.06.02 - v. 0.7 - refresh template MD5 when template mtime changes; check cp/systemctl; quoted paths; EXIT trap for footer
# 2026.05.26 - user-facing messages translated from Polish to English
# 2021.09.19 - v. 0.6 - added wypisywanie kropek, by ladniej wygladalo
# 2021.06.17 - v. 0.5 - md5 of template file is computed first
# 2021.02.02 - v. 0.4 - added call for script header and footer
# 2021.01.17 - v. 0.3 - changed from inotifywait to md5sum change detection
# 2021.01.13 - v. 0.2 - added "-e attrib" to inotifywait 
# 2020.12.03 - v. 0.1 - initial release, program produces no screen output.

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

bylo 120s ale chyba to za malo bo 2x skrypt wyslal maila w dniu 20.01.2021

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

file=/etc/lighttpd/lighttpd.conf
template_file=/etc/lighttpd/lighttpd.conf.dobry-dziala

delay_sec=300    # delay_sec w sekundach po ktorych dopiero odwracamy zmiane pliku (by np. update skonczyl sie)
                  # bylo 120s ale chyba to za malo bo 2x skrypt wyslal maila w dniu 20.01.2021
co_ile_spr=30
co_ile_wypisac_date=200

tresc_maila="File ${file} was modified; the default configuration was restored."

lighttpd_template_md5() {
  md5sum "$template_file" | awk '{print $1}'
}

lighttpd_refresh_template_md5_if_needed() {
  local mtime
  mtime=$(stat -c %Y "$template_file" 2>/dev/null) || return 1
  if [[ "$mtime" != "${template_mtime_last:-}" ]]; then
    template_mtime_last=$mtime
    md5_template=$(lighttpd_template_md5) || return 1
  fi
  return 0
}

lighttpd_watch_cleanup() {
  . /root/bin/_script_footer.sh
}
trap lighttpd_watch_cleanup EXIT

if [[ ! -f "$file" ]]; then
  echo "file $file does not exist - exiting...."
  exit 1
fi
if [[ ! -f "$template_file" ]]; then
  echo "file $template_file does not exist - exiting...."
  exit 2
fi

template_mtime_last=
md5_template=$(lighttpd_template_md5) || exit 3

shopt -s nocasematch

licznik=0
echo -n "$(date '+%Y.%m.%d %H:%M:%S') "
while : ; do
    lighttpd_refresh_template_md5_if_needed || echo "WARNING: could not refresh template MD5 for $template_file" >&2
    if [[ $(md5sum "$file" | awk '{print $1}') != "${md5_template}" ]]; then
      echo   # blank line: previous output often had no trailing newline
      echo "$(date '+%Y.%m.%d %H:%M:%S') - detected file change - sending mail"
      sleep "$delay_sec"
      if ! cp "$template_file" "$file"; then
        echo "ERROR: failed to restore $file from $template_file" >&2
      elif ! systemctl restart lighttpd; then
        echo "ERROR: systemctl restart lighttpd failed after restoring $file" >&2
      else
        echo "$tresc_maila" | strings | /usr/bin/mailx -s "($(hostname)-$(date '+%Y.%m.%d %H:%M:%S')) ${file} modification reverted" "matuszyk+$(hostname)@matuszyk.com"
      fi
      licznik=0
    else
       sleep "$co_ile_spr"
       echo -n "."
       ((licznik++))
       if (( licznik == co_ile_wypisac_date )); then
         echo
         echo -n "$(date '+%Y.%m.%d %H:%M:%S') "
         licznik=0
       fi
    fi
done
