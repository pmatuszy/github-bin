#!/bin/bash
# v. 20260716.164924 - source _script_header.sh before -v (print_version_banner)

# 2026.06.18 - v. 0.8 - show resolved script version after startup banner (PuTTY / interactive)
# 2026.06.02 - v. 0.7 - each line: timestamp, [ avg: x.x ], then all core temps (one decimal, space-separated); x86 uses coretemp Core 0..N; single-sensor hosts show avg + one value
# 2026.06.02 - v. 0.6 - drop _script_cli.sh; inline print_version_banner in this script
# 2026.06.02 - v. 0.5 - rename NO_STARTUP_DELAY to --no_startup_delay
# 2026.06.02 - v. 0.4 - add -h/--help and -v/--version options (parsed before the header so they skip the figlet banner / startup delay)
# 2026.06.02 - v. 0.3 - auto-detect the real CPU sensor (x86_pkg_temp/coretemp on Intel, cpu-thermal on Raspberry Pi) instead of hard-coding thermal_zone0 (which is ambient acpitz on x86); print the chosen sensor
# 2026.06.02 - v. 0.2 - require readable thermal_zone0; EXIT trap runs footer; modern $(date) / quoted paths
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Continuously print CPU temperature(s) every 3 seconds until Ctrl-C.

Each line is:
  <timestamp>  [ avg: x.x ]  t0  t1  t2  ...
where avg is the mean of all core readings (one decimal) and t0..tN are per-core
temperatures in °C (one decimal, space-separated, no unit suffix on each core).

Sensor selection:
  - x86 with coretemp: all "Core N" hwmon inputs (Core 0, 1, 2, ...), not Package.
  - Otherwise: one CPU thermal sensor (e.g. Raspberry Pi cpu-thermal); avg and the
    single reading are the same value shown twice for a consistent layout.

Options:
  -h, --help        Show this help and exit.
  -v, --version     Print script version and exit.
  --no_startup_delay
                    Skip the random startup delay when run non-interactively
                    (see _script_header.sh).
EOF
}

# --- parse --no_startup_delay, then header, then -h/-v ---
HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

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
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done


if [[ -n "${SCRIPT_VERSION_NUMBER:-}" && "${SCRIPT_VERSION_NUMBER}" != unknown ]]; then
  if [[ -n "${SCRIPT_VERSION_DATE:-}" ]]; then
    echo "Running ${CALLER_SCRIPT_BASENAME} version ${SCRIPT_VERSION_NUMBER} (${SCRIPT_VERSION_DATE})"
  else
    echo "Running ${CALLER_SCRIPT_BASENAME} version ${SCRIPT_VERSION_NUMBER}"
  fi
  echo
fi

# Ordered list of sysfs temp paths (millidegrees C). Populated by detect_cpu_core_temp_paths.
CPU_CORE_TEMP_PATHS=()
CPU_TEMP_LABEL=""

# Read millidegrees from a sysfs temp file; print the value or return non-zero.
read_temp_mc() {
  local path="$1" mc
  [[ -r "$path" ]] || return 1
  mc="$(<"$path")"
  [[ "$mc" =~ ^-?[0-9]+$ ]] || return 1
  printf '%s' "$mc"
}

# Find one fallback CPU temp path when per-core coretemp labels are unavailable.
detect_single_cpu_temp_path() {
  local zone type want hw name lf label inp

  for want in x86_pkg_temp cpu-thermal cpu_thermal; do
    for zone in /sys/class/thermal/thermal_zone*; do
      [[ -r "$zone/type" && -r "$zone/temp" ]] || continue
      type="$(<"$zone/type")"
      if [[ "$type" == "$want" ]]; then
        printf '%s' "$zone/temp"
        CPU_TEMP_LABEL="thermal zone '${type}' (single sensor)"
        return 0
      fi
    done
  done

  for zone in /sys/class/thermal/thermal_zone*; do
    [[ -r "$zone/type" && -r "$zone/temp" ]] || continue
    type="$(<"$zone/type")"
    if [[ "${type,,}" == *cpu* ]]; then
      printf '%s' "$zone/temp"
      CPU_TEMP_LABEL="thermal zone '${type}' (single sensor)"
      return 0
    fi
  done

  if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    printf '%s' /sys/class/thermal/thermal_zone0/temp
    CPU_TEMP_LABEL="thermal_zone0 (single sensor; may be ambient on x86)"
    return 0
  fi

  return 1
}

# Prefer coretemp "Core N" inputs (sorted by N); else one thermal-zone sensor.
detect_cpu_core_temp_paths() {
  local hw name lf label inp core_n single

  CPU_CORE_TEMP_PATHS=()
  CPU_TEMP_LABEL=""

  for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    name="$(<"$hw/name")"
    [[ "$name" == coretemp ]] || continue
    mapfile -t CPU_CORE_TEMP_PATHS < <(
      for lf in "$hw"/temp*_label; do
        [[ -r "$lf" ]] || continue
        label="$(<"$lf")"
        if [[ "$label" =~ ^Core[[:space:]]+([0-9]+)$ ]]; then
          core_n="${BASH_REMATCH[1]}"
          inp="${lf%_label}_input"
          [[ -r "$inp" ]] || continue
          printf '%04d %s\n' "$core_n" "$inp"
        fi
      done | sort -n -k1,1 | awk '{print $2}'
    )
    if (( ${#CPU_CORE_TEMP_PATHS[@]} > 0 )); then
      CPU_TEMP_LABEL="coretemp per-core (${#CPU_CORE_TEMP_PATHS[@]} cores)"
      return 0
    fi
  done

  single="$(detect_single_cpu_temp_path)" || return 1
  CPU_CORE_TEMP_PATHS=( "$single" )
  return 0
}

# Print: <timestamp>  [ avg: x.x ]  core0  core1  ...
print_cpu_temp_line() {
  local path mc sum=0 count=0
  local -a mcs=()
  local avg_part core_part t

  for path in "${CPU_CORE_TEMP_PATHS[@]}"; do
    mc="$(read_temp_mc "$path")" || continue
    mcs+=( "$mc" )
    sum=$(( sum + mc ))
    (( ++count ))
  done

  if (( count == 0 )); then
    echo "ERROR: could not read any CPU temperature sensor" >&2
    return 1
  fi

  avg_part="$(awk -v s="$sum" -v c="$count" 'BEGIN { printf "%.1f", (s / c) / 1000 }')"
  core_part=""
  for mc in "${mcs[@]}"; do
    t="$(awk -v m="$mc" 'BEGIN { printf "%.1f", m/1000 }')"
    core_part+="${core_part:+ }${t}"
  done

  printf '%s  [ avg: %s ] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$avg_part" "$core_part"
}

if ! detect_cpu_core_temp_paths; then
  echo "ERROR: no readable CPU temperature sensor found (checked coretemp cores and /sys/class/thermal)."
  exit 1
fi

cpu_temp_cleanup() {
  . /root/bin/_script_footer.sh
}
trap cpu_temp_cleanup EXIT

echo "CPU temperature: ${CPU_TEMP_LABEL}"
for path in "${CPU_CORE_TEMP_PATHS[@]}"; do
  echo "  ${path}"
done
echo

while : ; do
  print_cpu_temp_line || true
  sleep 3
done
