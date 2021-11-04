#!/bin/bash
# 2021.11.04 - v. 0.1 - initial release (date unknown)

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://www8.garmin.com/support/download_details.jsp?id=14337"

temat_maila="(`date '+%Y.%m.%d %H:%M'`) GPSMAP 66 firmware update"
timeout=300
kill_after=310
rozmiar_x_ekran=900
rozmiar_y_ekran=700
rozmiar_x_crop=800
rozmiar_y_crop=700
rozmiar_x_crop_offset=0
rozmiar_y_crop_offset=0

max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=1000 # w ms

javascript=off

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, ${rozmiar_x_ekran}x${rozmiar_y_ekran}x24" cutycapt --max-wait=${max_wait_na_strone} --delay=${delay_po_wczytaniu_strony} --min-width=${rozmiar_x_ekran} --min-height=${rozmiar_y_ekran} --javascript=${javascript} --url=${URL} --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop ${rozmiar_x_crop}x${rozmiar_y_crop}+${rozmiar_x_crop_offset}+${rozmiar_y_crop_offset} "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

mpack -s "${temat_maila}" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day, ${URL}" -a "${plik_po_cropie}" --note-to-self 2>&1 > /dev/null
/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`]" array:string:"${plik_po_cropie}" string:+41763691467

rm "${plik_po_cropie}" "${plik_bez_cropa}"
