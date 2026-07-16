#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.32 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2025.10.27 - v. 0.31- bugfix: check if it is run on raspberry pi hardware - ChatGPT helped on that one
# 2025.10.27 - v. 0.3 - bugfix: if mem < 1GB it was not properly formatted and displayed 0 GB - ChatGPT helped on that one
# 2020.12.08 - v. 0.2 - adding info about total RAM
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

# tr -d '\0'` below is to get rid of the message "warning: command substitution: ignored null byte in input"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Print Raspberry Pi model (from device-tree) and total RAM. Exits with an error if
the machine is not a Raspberry Pi.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively.
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

if (( ! script_is_run_interactively ));then    # jesli nie interaktywnie, to chcemy wyswietlic info, by poszlo do logow
  echo "${SCRIPT_VERSION}";echo
fi

if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "Running on Raspberry Pi hardware"
else
    echo "Not a Raspberry Pi";echo
    . /root/bin/_script_footer.sh
    exit 1
fi

echo
echo "$(tr -d '\0' </proc/device-tree/model),   $(awk '/MemTotal/ {printf "Total RAM: %.2f GB", $2/1024/1024}' /proc/meminfo)"
#echo `cat /proc/device-tree/model|tr -d '\0'` ",   " `cat /proc/meminfo |grep MemTotal|awk '{printf ("Total RAM: %.0f GB", $2/1024/1024)}'`
echo

. /root/bin/_script_footer.sh

