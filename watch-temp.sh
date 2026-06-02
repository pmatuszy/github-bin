#!/bin/bash

# 2026.06.02 - v. 0.2 - Raspberry Pi: rich vcgencmd live view (SoC temp + ARM clock + core voltage + decoded throttle/under-voltage status) instead of the bare one-line `sensors`; auto-detect Pi vs x86 (x86 keeps `sensors`); fall back to sensors if vcgencmd is missing; remove stray debug echo; guard virt-what when absent
# 2025.11.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export DISPLAY=
WATCH_INTERVAL="${WATCH_TEMP_INTERVAL:-1}"

# Refuse to run inside a VM (temperature sensors are meaningless there). Only enforced when
# virt-what is available; missing virt-what must not abort the script.
if command -v virt-what >/dev/null 2>&1; then
  if (( $(virt-what 2>/dev/null | wc -l) != 0 )); then
    echo ; echo "host is NOT a physical machine ... exiting..." ; echo
    exit 1
  fi
fi

is_raspberry_pi() {
  local model=""
  if [[ -r /proc/device-tree/model ]]; then
    model="$(tr -d '\0' </proc/device-tree/model 2>/dev/null)"
  fi
  if [[ "$model" == *[Rr]aspberry* ]]; then
    return 0
  fi
  command -v vcgencmd >/dev/null 2>&1
}

# Self-contained Raspberry Pi status block (exported so `watch` can re-run it each tick).
# Uses vcgencmd for SoC temperature, ARM clock, core voltage and the throttling bitmask,
# which it decodes into readable warnings. No dependency on outer-script variables.
render_pi_status() {
  local vc model now host temp_c clock_hz clock_mhz volts throttled t_hex t_dec
  local -a msgs=()

  vc="$(command -v vcgencmd 2>/dev/null || true)"
  now="$(date '+%Y-%m-%d %H:%M:%S')"
  host="$(hostname 2>/dev/null || echo '?')"
  model=""
  if [[ -r /proc/device-tree/model ]]; then
    model="$(tr -d '\0' </proc/device-tree/model 2>/dev/null)"
  fi

  echo "${model:-Raspberry Pi} - ${host}    ${now}"
  echo

  # SoC temperature (vcgencmd, else thermal_zone0).
  if [[ -n "$vc" ]] && temp_c="$("$vc" measure_temp 2>/dev/null)"; then
    temp_c="${temp_c#temp=}"
    temp_c="${temp_c%\'C}"
    printf '  CPU temp : %s C\n' "$temp_c"
  elif [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    printf '  CPU temp : %s C\n' "$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)"
  fi

  # ARM clock (Hz -> MHz).
  if [[ -n "$vc" ]] && clock_hz="$("$vc" measure_clock arm 2>/dev/null)"; then
    clock_hz="${clock_hz#*=}"
    if [[ "$clock_hz" =~ ^[0-9]+$ ]]; then
      clock_mhz=$(( clock_hz / 1000000 ))
      printf '  ARM clock: %s MHz\n' "$clock_mhz"
    fi
  fi

  # Core voltage.
  if [[ -n "$vc" ]] && volts="$("$vc" measure_volts core 2>/dev/null)"; then
    volts="${volts#volt=}"
    printf '  Core volt: %s\n' "$volts"
  fi

  # Throttling / under-voltage bitmask, decoded.
  if [[ -n "$vc" ]] && throttled="$("$vc" get_throttled 2>/dev/null)"; then
    t_hex="${throttled#throttled=}"
    if [[ "$t_hex" =~ ^0[xX][0-9a-fA-F]+$ || "$t_hex" =~ ^[0-9]+$ ]]; then
      t_dec=$(( t_hex ))
      (( t_dec & 0x1 ))     && msgs+=("under-voltage NOW")
      (( t_dec & 0x2 ))     && msgs+=("ARM freq capped NOW")
      (( t_dec & 0x4 ))     && msgs+=("throttled NOW")
      (( t_dec & 0x8 ))     && msgs+=("soft temp limit NOW")
      (( t_dec & 0x10000 )) && msgs+=("under-voltage occurred")
      (( t_dec & 0x20000 )) && msgs+=("ARM freq capping occurred")
      (( t_dec & 0x40000 )) && msgs+=("throttling occurred")
      (( t_dec & 0x80000 )) && msgs+=("soft temp limit occurred")
      if (( ${#msgs[@]} == 0 )); then
        printf '  Throttle : OK (%s)\n' "$t_hex"
      else
        local joined=""
        local m
        for m in "${msgs[@]}"; do
          joined+="${joined:+; }${m}"
        done
        printf '  Throttle : %s  [%s]\n' "$joined" "$t_hex"
      fi
    else
      printf '  Throttle : %s\n' "$throttled"
    fi
  fi
}

if is_raspberry_pi; then
  if command -v vcgencmd >/dev/null 2>&1; then
    export -f render_pi_status
    watch -t -n "$WATCH_INTERVAL" "bash -c render_pi_status"
  else
    echo "NOTE: vcgencmd not found (install package raspberrypi-utils / libraspberrypi-bin for the rich view)."
    echo "      Falling back to 'sensors'."
    echo
    check_if_installed sensors
    watch -n "$WATCH_INTERVAL" sensors
  fi
else
  # x86 / other hardware: lm-sensors shows per-core coretemp, NVMe, etc.
  check_if_installed sensors nvme-cli
  if ! type -fP sensors >/dev/null 2>&1; then
    echo ; echo "(PGM) I can't find sensors utility... exiting ..." ; echo
    exit 1
  fi
  watch -n "$WATCH_INTERVAL" sensors
fi

. /root/bin/_script_footer.sh
