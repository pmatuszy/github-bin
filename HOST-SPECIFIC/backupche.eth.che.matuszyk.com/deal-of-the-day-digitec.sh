#!/bin/bash
# 2021.08.06 - v. 0.4 - sending dbus signal message
# 2021.06.22 - v. 0.3 - URL set and used throughout the script, added timeout as signal-cli can be run in the background and this script would never finish
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR, ,added -u option
# 2021.05.20 - v. 0.1 - initial release (date unknown)

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://www.digitec.ch/en/LiveShopping"
timeout=300
kill_after=310
rozmiar_x_ekran=900
rozmiar_y_ekran=700
rozmiar_x_crop=800
rozmiar_y_crop=700
max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=1000 # w ms

javascript=off

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, ${rozmiar_x_ekran}x${rozmiar_y_ekran}x24" cutycapt --max-wait=${max_wait_na_strone} --delay=${delay_po_wczytaniu_strony} --min-width=${rozmiar_x_ekran} --min-height=${rozmiar_y_ekran} --javascript=${javascript} --url=${URL} --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop 800x800+3+5 "${plik_po_cropie}"

echo "${URL}" | aha | > "${zawartosc_maila}"

mpack -s "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day, ${URL}" -a "${plik_po_cropie}" --note-to-self 2>&1 > /dev/null
# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`]" array:string:"${plik_po_cropie}" string:+41763691467

rm "${plik_po_cropie}" "${plik_bez_cropa}"
