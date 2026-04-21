#!/bin/bash

# 2026.04.21 - v. 0.2 - require procps-ng GNU watch (-w/--no-wrap; sub-second -n); document intent
# 2023.01.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed figlet watch

# Needs procps-ng `watch` (Linux): -t (no header), -w (no line wrap), fractional -n (e.g. 0.1s).
# BSD/macOS watch is different and will not work as-is.
require_gnu_watch() {
  local h
  h=$(watch -h 2>&1 || true)
  [[ -z "$h" ]] && h=$(watch --help 2>&1 || true)
  if ! grep -qE -- '(--no-wrap|[[:space:]]-w[,[:space:]])' <<<"$h"; then
    echo "(PGM) This script requires GNU procps-ng watch (-w / --no-wrap and sub-second -n). See time-watch.sh header." >&2
    exit 1
  fi
}
require_gnu_watch

sleep 2
watch -w -t -n0.1 "date '+%Y.%m.%d %H:%M:%S' | figlet -w 140 -f big"

. /root/bin/_script_footer.sh
