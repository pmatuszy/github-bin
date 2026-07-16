#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.02.02 - v. 0.8 - added --foreground option to be able to use Ctrl-C
# 2022.04.13 - v. 0.7 - specyfikacja pelnej sciezki do chromium (wtedy dziala z crontaba)
# 2022.01.05 - v. 0.6 - zmiana cutycapt na firefoxa bo nie generowala sie strona ladnie
# 2021.11.04 - v. 0.5 - dodanie *crop_offset i temat_maila
# 2021.08.06 - v. 0.4 - sending dbus signal message
# 2021.06.22 - v. 0.3 - URL set and used throughout the script, added timeout as signal-cli can be run in the background and this script would never finish
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR, ,added -u option
# 2021.05.20 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

mpack -s "\${temat_maila}" -c image/jpeg "\${plik_po_cropie}" -d "\${zawartosc_maila}" matuszyk@matuszyk.com

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

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

export URL="https://gopro.com/en/ch/update/hero4"
temat_maila="(`date '+%Y.%m.%d %H:%M'`) GoPro4 firmware update"

timeout=300
kill_after=310
rozmiar_x_ekran=1100
rozmiar_y_ekran=900
rozmiar_x_crop=710
rozmiar_y_crop=650
rozmiar_x_crop_offset=330
rozmiar_y_crop_offset=180

max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=1000 # w ms

cd /tmp
plik_bez_cropa=`TMPDIR=$(pwd) mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`

/usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /snap/bin/chromium --user-data-dir=/tmp --headless --no-sandbox --disable-gpu --ignore-certificate-error --ignore-ssl-errors --hide-scrollbars --window-size="${rozmiar_x_ekran},${rozmiar_y_ekran}" --screenshot="${plik_bez_cropa}" "${URL}" 2>/dev/null

convert "/tmp/snap.chromium${plik_bez_cropa}" -crop ${rozmiar_x_crop}x${rozmiar_y_crop}+${rozmiar_x_crop_offset}+${rozmiar_y_crop_offset} "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

# mpack -s "${temat_maila}" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

/usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`] ${URL}" array:string:"${plik_po_cropie}" string:+41763691467

rm "/tmp/snap.chromium${plik_po_cropie}" "/tmp/snap.chromium${plik_bez_cropa}" "${zawartosc_maila}"
