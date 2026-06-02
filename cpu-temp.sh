#!/bin/bash

# 2026.06.02 - v. 0.6 - drop _script_cli.sh; inline print_version_banner in this script
# 2026.06.02 - v. 0.5 - rename NO_STARTUP_DELAY to --no_startup_delay
# 2026.06.02 - v. 0.4 - add -h/--help and -v/--version options (parsed before the header so they skip the figlet banner / startup delay)
# 2026.06.02 - v. 0.3 - auto-detect the real CPU sensor (x86_pkg_temp/coretemp on Intel, cpu-thermal on Raspberry Pi) instead of hard-coding thermal_zone0 (which is ambient acpitz on x86); print the chosen sensor
# 2026.06.02 - v. 0.2 - require readable thermal_zone0; EXIT trap runs footer; modern $(date) / quoted paths
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

print_version_banner() {
  local ver=unknown date= line title verline width=60
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  title="$(basename "$0")"
  if [[ -n "$date" ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Continuously print the CPU temperature (every 3 seconds) until Ctrl-C.

The CPU sensor is auto-detected so the same script is correct on different hardware:
  - Intel/x86: the coretemp package sensor (x86_pkg_temp thermal zone or
    coretemp hwmon "Package id 0") rather than the ambient acpitz zone.
  - Raspberry Pi: the cpu-thermal zone (thermal_zone0).
  - Fallback: thermal_zone0 if nothing more specific is found.

Options:
  -h, --help        Show this help and exit.
  -v, --version     Print script version and exit.
  --no_startup_delay
                    Skip the random startup delay when run non-interactively
                    (see _script_header.sh).
EOF
}

# --- parse options before sourcing the header (avoids figlet/delay on --help/--version) ---
HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

# Auto-detect the best CPU temperature source for this machine.
# On Raspberry Pi, thermal_zone0 is the CPU (cpu-thermal). On x86, thermal_zone0 is usually
# the ACPI ambient zone (acpitz) and the real CPU temperature lives in the Intel coretemp
# driver (x86_pkg_temp thermal zone, or coretemp hwmon "Package id 0"). We pick by sensor
# type so the same script is correct on both, then fall back to thermal_zone0.
# Sets globals: CPU_TEMP_PATH (sysfs *_input/temp file, value in milli-degrees C) and
# CPU_TEMP_LABEL (human description). Returns non-zero if nothing readable was found.
CPU_TEMP_PATH=""
CPU_TEMP_LABEL=""

detect_cpu_temp_path() {
  local zone type want hw name lf label inp

  # 1) Thermal zone whose type names a CPU/package sensor (preferred, exact match first).
  for want in x86_pkg_temp cpu-thermal cpu_thermal; do
    for zone in /sys/class/thermal/thermal_zone*; do
      [[ -r "$zone/type" && -r "$zone/temp" ]] || continue
      type="$(<"$zone/type")"
      if [[ "$type" == "$want" ]]; then
        CPU_TEMP_PATH="$zone/temp"
        CPU_TEMP_LABEL="thermal zone '${type}'"
        return 0
      fi
    done
  done

  # Any thermal zone whose type merely contains "cpu".
  for zone in /sys/class/thermal/thermal_zone*; do
    [[ -r "$zone/type" && -r "$zone/temp" ]] || continue
    type="$(<"$zone/type")"
    if [[ "${type,,}" == *cpu* ]]; then
      CPU_TEMP_PATH="$zone/temp"
      CPU_TEMP_LABEL="thermal zone '${type}'"
      return 0
    fi
  done

  # 2) Intel coretemp via hwmon: prefer the "Package id 0" input, else the first core input.
  for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    name="$(<"$hw/name")"
    [[ "$name" == coretemp ]] || continue
    for lf in "$hw"/temp*_label; do
      [[ -r "$lf" ]] || continue
      label="$(<"$lf")"
      if [[ "$label" == "Package id 0" ]]; then
        inp="${lf%_label}_input"
        if [[ -r "$inp" ]]; then
          CPU_TEMP_PATH="$inp"
          CPU_TEMP_LABEL="coretemp '${label}'"
          return 0
        fi
      fi
    done
    for inp in "$hw"/temp*_input; do
      [[ -r "$inp" ]] || continue
      CPU_TEMP_PATH="$inp"
      CPU_TEMP_LABEL="coretemp"
      return 0
    done
  done

  # 3) Fallback: thermal_zone0 (correct on Raspberry Pi; ambient acpitz on some x86 boxes).
  if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    CPU_TEMP_PATH=/sys/class/thermal/thermal_zone0/temp
    CPU_TEMP_LABEL="thermal_zone0 (fallback; may be ambient, not CPU, on x86)"
    return 0
  fi

  return 1
}

if ! detect_cpu_temp_path; then
  echo "ERROR: no readable CPU temperature sensor found (checked /sys/class/thermal and coretemp hwmon)."
  exit 1
fi

cpu_temp_cleanup() {
  . /root/bin/_script_footer.sh
}
trap cpu_temp_cleanup EXIT

echo "CPU temperature sensor: ${CPU_TEMP_LABEL}"
echo "  source: ${CPU_TEMP_PATH}"
echo

while : ; do
  echo "$(date '+%Y-%m-%d %H:%M:%S')" "$(awk '{printf "%3.1f C\n", $1/1000}' "$CPU_TEMP_PATH")"
  sleep 3
done
