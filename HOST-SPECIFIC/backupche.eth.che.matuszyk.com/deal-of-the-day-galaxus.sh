#!/bin/bash
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR
# 2021.05.20 - v. 0.1 - initial release (date unknown)

XDG_RUNTIME_DIR=/encrypted/root/XDG_DATA_HOME

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, 800x600x24" cutycapt  --url=https://www.galaxus.ch/en --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop 800x800+3+5 "${plik_po_cropie}"

echo "https://www.galaxus.ch/en/LiveShopping" > "${zawartosc_maila}"

mpack -s "(`date '+%Y.%m.%d %H:%M'`) galaxus.ch-Deal of the Day" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

/opt/signal-cli/bin/signal-cli send -m "(`date '+%Y.%m.%d %H:%M'`) Galaxus.ch-Deal of the Day, https://www.galaxus.ch/en/LiveShopping" -a "${plik_po_cropie}" --note-to-self 2>/dev/null

rm "${plik_po_cropie}" "${plik_bez_cropa}"

