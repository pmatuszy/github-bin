#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.7 - refresh template MD5 when template mtime changes; check cp/systemctl; quoted paths; EXIT trap for footer
# 2026.05.26 - user-facing messages translated from Polish to English
# 2021.09.19 - v. 0.6 - dodalem wypisywanie kropek, by ladniej wygladalo
# 2021.06.17 - v. 0.5 - najpierw jest przeliczana md5 suma pliku plik_template
# 2021.02.02 - v. 0.4 - added call for script header and footer
# 2021.01.17 - v. 0.3 - changed from inotifywait to md5sum change detection
# 2021.01.13 - v. 0.2 - added "-e attrib" to inotifywait 
# 2020.12.03 - v. 0.1 - initial release, program nie generuje zadnego output na ekran.

. /root/bin/_script_header.sh

plik=/etc/lighttpd/lighttpd.conf
plik_template=/etc/lighttpd/lighttpd.conf.dobry-dziala

opoznienie=300    # opoznienie w sekundach po ktorych dopiero odwracamy zmiane pliku (by np. update skonczyl sie)
                  # bylo 120s ale chyba to za malo bo 2x skrypt wyslal maila w dniu 20.01.2021
co_ile_spr=30
co_ile_wypisac_date=200

tresc_maila="File ${plik} was modified; the default configuration was restored."

lighttpd_template_md5() {
  md5sum "$plik_template" | awk '{print $1}'
}

lighttpd_refresh_template_md5_if_needed() {
  local mtime
  mtime=$(stat -c %Y "$plik_template" 2>/dev/null) || return 1
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

if [[ ! -f "$plik" ]]; then
  echo "file $plik does not exist - exiting...."
  exit 1
fi
if [[ ! -f "$plik_template" ]]; then
  echo "file $plik_template does not exist - exiting...."
  exit 2
fi

template_mtime_last=
md5_template=$(lighttpd_template_md5) || exit 3

shopt -s nocasematch

licznik=0
echo -n "$(date '+%Y.%m.%d %H:%M:%S') "
while : ; do
    lighttpd_refresh_template_md5_if_needed || echo "WARNING: could not refresh template MD5 for $plik_template" >&2
    if [[ $(md5sum "$plik" | awk '{print $1}') != "${md5_template}" ]]; then
      echo   # blank line: previous output often had no trailing newline
      echo "$(date '+%Y.%m.%d %H:%M:%S') - detected file change - sending mail"
      sleep "$opoznienie"
      if ! cp "$plik_template" "$plik"; then
        echo "ERROR: failed to restore $plik from $plik_template" >&2
      elif ! systemctl restart lighttpd; then
        echo "ERROR: systemctl restart lighttpd failed after restoring $plik" >&2
      else
        echo "$tresc_maila" | strings | /usr/bin/mailx -s "($(hostname)-$(date '+%Y.%m.%d %H:%M:%S')) ${plik} modification reverted" "matuszyk+$(hostname)@matuszyk.com"
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
