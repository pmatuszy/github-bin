#!/bin/bash
# 2022.04.13 - v. 0.7 - specyfikacja pelnej sciezki do chromium (wtedy dziala z crontaba)
# 2022.01.05 - v. 0.6 - zmiana cutycapt na firefoxa bo nie generowala sie strona ladnie
# 2021.11.04 - v. 0.5 - dodanie *crop_offset i temat_maila
# 2021.08.06 - v. 0.4 - sending dbus signal message
# 2021.06.22 - v. 0.3 - URL set and used throughout the script, added timeout as signal-cli can be run in the background and this script would never finish
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR, ,added -u option
# 2021.05.20 - v. 0.1 - initial release (date unknown)

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://www.intel.com/content/www/us/en/download/19239/bios-update-dnkbli7v.html"
temat_maila="(`date '+%Y.%m.%d %H:%M'`) nuci7 firmware update"

timeout=300
kill_after=310
rozmiar_x_ekran=900
rozmiar_y_ekran=900
rozmiar_x_crop=750
rozmiar_y_crop=800
rozmiar_x_crop_offset=80
rozmiar_y_crop_offset=150

max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=1000 # w ms

cd /tmp
plik_bez_cropa=`TMPDIR=$(pwd) mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`

/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /snap/bin/chromium --user-data-dir=/tmp --headless --no-sandbox --disable-gpu --ignore-certificate-error --ignore-ssl-errors --hide-scrollbars --window-size="${rozmiar_x_ekran},${rozmiar_y_ekran}" --screenshot="${plik_bez_cropa}" "${URL}" 2>/dev/null

convert "/tmp/snap.chromium${plik_bez_cropa}" -crop ${rozmiar_x_crop}x${rozmiar_y_crop}+${rozmiar_x_crop_offset}+${rozmiar_y_crop_offset} "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

mpack -s "${temat_maila}" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day, ${URL}" -a "${plik_po_cropie}" --note-to-self 2>&1 > /dev/null
/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`] ${URL}" array:string:"${plik_po_cropie}" string:+41763691467

rm "/tmp/snap.chromium${plik_po_cropie}" "${plik_bez_cropa}" "${zawartosc_maila}"
