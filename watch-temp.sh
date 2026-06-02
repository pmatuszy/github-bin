#!/bin/bash

# 2026.06.02 - v. 0.5 - Pi view: annotate the healthy throttle line ("OK (0x0)  <- no under-voltage / no throttling, now or since boot") so the bitmask is self-explanatory
# 2026.06.02 - v. 0.4 - Pi view: no temp file and no exported function — render in-process via a shell function in a clear+sleep loop (ANSI home/clear gives the same non-scrolling refresh as watch); x86 still uses `watch sensors`
# 2026.06.02 - v. 0.3 - fix: run the Pi view via a temp render script executed by watch (the exported-function approach failed because watch's `sh -c` dropped the BASH_FUNC_* env entry -> "render_pi_status: command not found")
# 2026.06.02 - v. 0.2 - Raspberry Pi: rich vcgencmd live view (SoC temp + ARM clock + core voltage + decoded throttle/under-voltage status) instead of the bare one-line `sensors`; auto-detect Pi vs x86 (x86 keeps `sensors`); fall back to sensors if vcgencmd is missing; remove stray debug echo; guard virt-what when absent
# 2025.11.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export DISPLAY=
WATCH_INTERVAL="${WATCH_TEMP_INTERVAL:-1}"

watch_temp_cleanup() {
  . /root/bin/_script_footer.sh
}
trap watch_temp_cleanup EXIT

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

# Self-contained Raspberry Pi status block, called directly in the refresh loop below (same
# shell — no temp file, no exported function). Uses vcgencmd for SoC temperature, ARM clock,
# core voltage and the throttling bitmask, which it decodes into readable warnings.
render_pi_status() {
  local vc now host model temp_c clock_hz volts throttled t_hex t_dec joined m
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

  if [[ -n "$vc" ]] && temp_c="$("$vc" measure_temp 2>/dev/null)"; then
    temp_c="${temp_c#temp=}"
    temp_c="${temp_c%\'C}"
    printf '  CPU temp : %s C\n' "$temp_c"
  elif [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    printf '  CPU temp : %s C\n' "$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)"
  fi

  if [[ -n "$vc" ]] && clock_hz="$("$vc" measure_clock arm 2>/dev/null)"; then
    clock_hz="${clock_hz#*=}"
    if [[ "$clock_hz" =~ ^[0-9]+$ ]]; then
      printf '  ARM clock: %s MHz\n' "$(( clock_hz / 1000000 ))"
    fi
  fi

  if [[ -n "$vc" ]] && volts="$("$vc" measure_volts core 2>/dev/null)"; then
    volts="${volts#volt=}"
    printf '  Core volt: %s\n' "$volts"
  fi

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
        printf '  Throttle : OK (%s)   <- no under-voltage / no throttling, now or since boot\n' "$t_hex"
      else
        joined=""
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

# In-process refresh loop: clear (cursor home + erase) then redraw, like watch but without a
# temp file or a child shell. Ctrl-C is handled by the header's INT trap.
watch_render_loop() {
  while : ; do
    printf '\033[H\033[2J'
    render_pi_status
    sleep "$WATCH_INTERVAL"
  done
}

if is_raspberry_pi; then
  if command -v vcgencmd >/dev/null 2>&1; then
    watch_render_loop
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
