#!/bin/bash

# 2026.04.21 - v. 0.1 - RAM report: /proc/meminfo + free -h, boxed sections; help/version

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  cat <<'EOF'
Usage: mem-info.sh [-h|--help] [-v|--version]

Print a readable RAM report for the local Linux system: summary (with the
kernel’s MemAvailable estimate), full free(1) output, and every field from
/proc/meminfo with kB and human-readable columns.

MemAvailable is usually the best “how much RAM can I use?” number; MemFree
ignores reclaimable cache.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.

Examples:
  mem-info.sh
  mem-info.sh | less -S
EOF
  exit 0
fi

if [[ "${1:-}" == -v || "${1:-}" == --version ]]; then
  _mi_ver=unknown
  _mi_date=
  while IFS= read -r _mi_line; do
    if [[ "$_mi_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
      _mi_date="${BASH_REMATCH[1]}"
      _mi_ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$_mi_date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$_mi_ver" "$_mi_date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$_mi_ver"
  fi
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo "(PGM) Unknown argument: $1" >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

. /root/bin/_script_header.sh

kod_powrotu=0

_mi_kb() {
  awk -v k="$1" '$1==k":" {print $2; exit}' /proc/meminfo
}

_mi_human_kb() {
  awk -v k="${1:-0}" 'BEGIN{
    k += 0
    if (k >= 1073741824) printf "%.2f TiB", k / 1073741824
    else if (k >= 1048576) printf "%.2f GiB", k / 1048576
    else if (k >= 1024) printf "%.2f MiB", k / 1024
    else printf "%d KiB", k
  }'
}

_mi_pct() {
  awk -v a="${1:-0}" -v b="${2:-1}" 'BEGIN{
    if (b + 0 <= 0) { print "?"; exit }
    printf "%.1f%%", 100 * a / b
  }'
}

echo
echo "(PGM) Memory (RAM) report — $(hostname) — $(date '+%Y-%m-%d %H:%M:%S %Z')" | boxes -a c -d stone
echo

mt=$(_mi_kb MemTotal) || mt=0
ma=$(_mi_kb MemAvailable) || ma=0
mf=$(_mi_kb MemFree) || mf=0
st=$(_mi_kb SwapTotal) || st=0
sf=$(_mi_kb SwapFree) || sf=0

{
  echo "MemTotal       $mt kB  ($(_mi_human_kb "$mt"))"
  echo "MemAvailable   $ma kB  ($(_mi_human_kb "$ma"))  ← practical “free” estimate"
  echo "MemFree        $mf kB  ($(_mi_human_kb "$mf"))  (unused; cache not counted)"
  echo "Available/Total  $(_mi_pct "$ma" "$mt") of RAM reported usable by kernel"
  if (( st > 0 )); then
    su=$((st - sf))
    echo "SwapTotal      $st kB  ($(_mi_human_kb "$st"))"
    echo "SwapFree       $sf kB  ($(_mi_human_kb "$sf"))  (Swap used: $su kB, $(_mi_human_kb "$su"))"
  else
    echo "Swap           none configured (SwapTotal 0)"
  fi
} | boxes -a l -d stone
echo

echo "(PGM) free -h" | boxes -a c -d stone
free -h | boxes -a l -d stone
echo

echo "(PGM) /proc/meminfo — all fields (kB + human)" | boxes -a c -d stone
{
  printf '%-30s %16s   %14s\n' "Field" "Value (kB)" "Human"
  printf '%-30s %16s   %14s\n' "------------------------------" "----------------" "--------------"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^([^:]+):\ +([0-9]+)\ +kB$ ]]; then
      key="${BASH_REMATCH[1]}"
      kb="${BASH_REMATCH[2]}"
      printf '%-30s %16s   %14s\n' "$key" "$kb" "$(_mi_human_kb "$kb")"
    elif [[ "$line" =~ ^([^:]+):\ +(.*)$ ]]; then
      printf '%-30s   %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    fi
  done < /proc/meminfo
} | boxes -a l -d stone
echo

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
