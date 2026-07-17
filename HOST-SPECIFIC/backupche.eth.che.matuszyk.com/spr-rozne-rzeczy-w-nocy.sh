#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2022.03.29 - v. 0.2 - shorter script names for screen; reduced delay between screen invocations from 4m to 45s
# 2022.03.05 - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

/root/bin/spr-kitchenaid-1.sh \

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

odstep_miedzy_wywolaniami=45s

for p in /root/bin/spr-deal-of-the-day-digitec.sh \
         /root/bin/spr-deal-of-the-day-galaxus.sh \
         /root/bin/spr-gopro10.sh \
         /root/bin/spr-GPSMAP-66.sh \
         /root/bin/spr-nuci7.sh \
         /root/bin/spr-nuci7b.sh \
         /root/bin/spr-nucvm.sh \
         /root/bin/spr-fenix.sh \
         /root/bin/spr-seagate-exos.sh \
         /root/bin/spr-veracrypt.sh

#        /root/bin/spr-kitchenaid-1.sh \
#        /root/bin/spr-kitchenaid-2.sh \

#         /root/bin/spr-WD-GOLD-16TB-digitec.sh \
#         /root/bin/spr-gopro4.sh \
#         /root/bin/spr-gopro7.sh \
  do
  /usr/bin/screen -c /dev/null -dmS "$(basename $p)" "$p"
  sleep ${odstep_miedzy_wywolaniami}
done
