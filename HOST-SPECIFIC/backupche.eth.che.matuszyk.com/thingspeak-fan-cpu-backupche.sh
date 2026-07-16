#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2021.10.19 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

echo "fan_speed = \$fan_speed CPUtemp = \$CPUtemp"

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

api_key='83BJNTPZVXHFUIQ0'

fan_speed=`argonone-cli --decode|grep 'Fan Status ON Speed'|sed 's/Fan Status ON Speed //'|tr -d "%"`
CPUtemp=`argonone-cli --decode|grep "System Temperature "|sed 's/System Temperature //'|tr -dc '0-9'`

# echo "fan_speed = $fan_speed CPUtemp = $CPUtemp"

curl --silent --data "api_key=$api_key&field1=$fan_speed&field2=$CPUtemp" https://api.thingspeak.com/update
