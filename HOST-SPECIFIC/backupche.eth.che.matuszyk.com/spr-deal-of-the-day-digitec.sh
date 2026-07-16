#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.02.02 - v. 0.6 - added --foreground option to be able to use Ctrl-C
# 2022.02.04 - v. 0.5 - added URL to Signal message
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

export URL="https://www.digitec.ch/en/LiveShopping"
export URL="https://www.digitec.ch/en/daily-deal"
temat_maila="(`date '+%Y.%m.%d %H:%M'`) digitec.ch-Deal of the Day"

timeout=300
kill_after=310
rozmiar_x_ekran=950
rozmiar_y_ekran=800
rozmiar_x_crop=950
rozmiar_y_crop=800
rozmiar_x_crop_offset=1
rozmiar_y_crop_offset=1
max_wait_na_strone=30000       # w ms
delay_po_wczytaniu_strony=3000 # w ms

javascript=off

plik_bez_cropa=`mktemp --dry-run --suffix=-bez-cropa.jpg`
plik_po_cropie=`mktemp --dry-run --suffix=-po-cropie.jpg`
zawartosc_maila=`mktemp --dry-run --suffix=.txt`
xvfb-run --server-args="-screen 0, ${rozmiar_x_ekran}x${rozmiar_y_ekran}x24" cutycapt --max-wait=${max_wait_na_strone} --delay=${delay_po_wczytaniu_strony} --min-width=${rozmiar_x_ekran} --min-height=${rozmiar_y_ekran} --javascript=${javascript} --url=${URL} --out="${plik_bez_cropa}"

convert "${plik_bez_cropa}" -crop ${rozmiar_x_crop}x${rozmiar_y_crop}+${rozmiar_x_crop_offset}+${rozmiar_y_crop_offset} "${plik_po_cropie}"

echo "${URL}" > "${zawartosc_maila}"

# mpack -s "${temat_maila}" -c image/jpeg "${plik_po_cropie}" -d "${zawartosc_maila}" matuszyk@matuszyk.com

/usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout /usr/bin/dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"[`date '+%Y.%m.%d %H:%M:%S'`] ${URL}" array:string:"${plik_po_cropie}" string:+41763691467 2>/dev/null >/dev/null

rm "${plik_po_cropie}" "${plik_bez_cropa}"
