#!/bin/bash

# 2026.04.21 - v. 0.2 - figlet width from COLUMNS; DATE_SHOW_INTERVAL; -u UTC; -h/-v; tput clear; drop redundant figlet check
# 2025.07.30 - v. 0.1 - initial release

utc=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'EOF'
Usage: date-show.sh [-h|--help] [-v|--version] [-u]

Full-screen loop: clear the terminal and show the current time as large banner
text (figlet). Stop with Ctrl+C.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  -u             Use UTC (same as date -u). Otherwise use local time; set TZ
                 to choose another zone (e.g. TZ=Europe/Warsaw date-show.sh).

Environment:
  DATE_SHOW_INTERVAL  Seconds between updates (default: 1). Fractions allowed
                      on GNU coreutils sleep (e.g. 0.99).
  COLUMNS             Terminal width for figlet -w (default: 80 if unset).
                      Typical shells set COLUMNS when interactive.

Clear:
  Uses tput clear when TERM is set and tput exists; otherwise clear(1).
EOF
      exit 0
      ;;
    -v|--version)
      _ds_ver=unknown
      _ds_date=
      while IFS= read -r _ds_line; do
        if [[ "$_ds_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
          _ds_date="${BASH_REMATCH[1]}"
          _ds_ver="${BASH_REMATCH[2]}"
          break
        fi
      done < "$0"
      if [[ -n "$_ds_date" ]]; then
        printf '%s version %s (%s)\n' "$(basename "$0")" "$_ds_ver" "$_ds_date"
      else
        printf '%s version %s\n' "$(basename "$0")" "$_ds_ver"
      fi
      exit 0
      ;;
    -u)
      utc=1
      shift
      ;;
    *)
      echo "(PGM) Unknown option: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

. /root/bin/_script_header.sh

interval="${DATE_SHOW_INTERVAL:-1}"
if ! [[ "$interval" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "(PGM) DATE_SHOW_INTERVAL must be a positive number; using 1" >&2
  interval=1
elif ! awk -v x="$interval" 'BEGIN{exit !(x>0)}' 2>/dev/null; then
  echo "(PGM) DATE_SHOW_INTERVAL must be > 0; using 1" >&2
  interval=1
fi

cols="${COLUMNS:-80}"
[[ "$cols" =~ ^[0-9]+$ ]] || cols=80
(( cols < 40 )) && cols=80
(( cols > 300 )) && cols=300

_ds_clear() {
  if [[ -n "${TERM:-}" ]] && command -v tput >/dev/null 2>&1; then
    tput clear
  else
    clear
  fi
}

while : ; do
  _ds_clear
  if (( utc )); then
    date -u '+%Y_%m_%d %H:%M:%S'
  else
    date '+%Y_%m_%d %H:%M:%S'
  fi | figlet -f banner -w "$cols"
  sleep "$interval"
done

. /root/bin/_script_footer.sh
