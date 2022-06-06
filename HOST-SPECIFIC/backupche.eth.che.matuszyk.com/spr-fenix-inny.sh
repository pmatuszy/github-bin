#!/bin/bash
# 2022.02.04 - v. 0.5 - added URL to Signal message
# 2021.08.06 - v. 0.4 - sending dbus signal message
# 2021.06.22 - v. 0.3 - URL set and used throughout the script, added timeout as signal-cli can be run in the background and this script would never finish
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR, ,added -u option
# 2021.05.20 - v. 0.1 - initial release (date unknown)

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://www.digitec.ch/en/s1/product/garmin-fenix-7x-sapphire-solar-51-mm-titanium-sports-watches-smartwatches-18358594?ip=fenix+7x"
temat_maila="(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day"

timeout=300
kill_after=310
rozmiar_x_ekran=950
rozmiar_y_ekran=800
rozmiar_x_crop=1050
rozmiar_y_crop=500
rozmiar_x_crop_offset=0
rozmiar_y_crop_offset=180
max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=1000 # w ms

javascript=off

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, ${rozmiar_x_ekran}x${rozmiar_y_ekran}x24" cutycapt --max-wait=${max_wait_na_strone} --delay=${delay_po_wczytaniu_strony} --min-width=${rozmiar_x_ekran} --min-height=${rozmiar_y_ekran} --javascript=${javascript} --url=${URL} --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop ${rozmiar_x_crop}x${rozmiar_y_crop}+${rozmiar_x_crop_offset}+${rozmiar_y_crop_offset} "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

# mpack -s "${temat_maila}" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day, ${URL}" -a "${plik_po_cropie}" --note-to-self 2>&1 > /dev/null
/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`] ${URL}" array:string:"${plik_po_cropie}" string:+41763691467 2>/dev/null >/dev/null

rm "${plik_po_cropie}" "${plik_bez_cropa}"

