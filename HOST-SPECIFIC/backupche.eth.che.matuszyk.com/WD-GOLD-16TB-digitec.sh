#!/bin/bash
# 2021.08.06 - v. 0.4 - sending dbus signal message
# 2021.06.22 - v. 0.3 - URL set and used throughout the script, added timeout as signal-cli can be run in the background and this script would never finish
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR, ,added -u option
# 2021.05.20 - v. 0.1 - initial release (date unknown)

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://www.digitec.ch/en/s1/product/wd-gold-16tb-35-hard-drives-13424026"
timeout=300
kill_after=310

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, 800x600x24" cutycapt  --url=${URL} --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop 800x800+3+5 "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

mpack -s "(`date '+%Y.%m.%d %H:%M'`)digitec.ch-WD GOLD 16TB" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

/usr/bin/timeout --preserve-status /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day, ${URL}" -a "${plik_po_cropie}" --note-to-self >/dev/null
/usr/bin/timeout --preserve-status /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`]" array:string:"${plik_po_cropie}" string:+41763691467

rm "${plik_po_cropie}" "${plik_bez_cropa}"
