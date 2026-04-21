#!/bin/bash

# 2026.04.21 - v. 0.4 - aligned summary box (MemTotal/MemAvailable/...) with printf columns
# 2026.04.21 - v. 0.3 - aligned /proc/meminfo table; bare integers (e.g. HugePages_*) get 3 columns
# 2026.04.21 - v. 0.2 - ASCII-only user-visible text (avoid ??? in non-UTF-8 / boxes)
# 2026.04.21 - v. 0.1 - RAM report: /proc/meminfo + free -h, boxed sections; help/version

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  cat <<'EOF'
Usage: mem-info.sh [-h|--help] [-v|--version]

Print a readable RAM report for the local Linux system: summary (with the
kernel's MemAvailable estimate), full free(1) output, and every field from
/proc/meminfo with kB and human-readable columns.

MemAvailable is usually the best "how much RAM can I use?" number; MemFree
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
echo "(PGM) Memory (RAM) report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S %Z')" | boxes -a c -d stone
echo

mt=$(_mi_kb MemTotal) || mt=0
ma=$(_mi_kb MemAvailable) || ma=0
mf=$(_mi_kb MemFree) || mf=0
st=$(_mi_kb SwapTotal) || st=0
sf=$(_mi_kb SwapFree) || sf=0

{
  _sl_lw=18
  _sl_nw=12
  _sl_hw=14
  printf '%-*s %*s kB  (%*s)\n' "$_sl_lw" "MemTotal" "$_sl_nw" "$mt" "$_sl_hw" "$(_mi_human_kb "$mt")"
  printf '%-*s %*s kB  (%*s)  <- practical "free" estimate\n' "$_sl_lw" "MemAvailable" "$_sl_nw" "$ma" "$_sl_hw" "$(_mi_human_kb "$ma")"
  printf '%-*s %*s kB  (%*s)  (unused; cache not counted)\n' "$_sl_lw" "MemFree" "$_sl_nw" "$mf" "$_sl_hw" "$(_mi_human_kb "$mf")"
  printf '%-*s %6s  %s\n' "$_sl_lw" "Available/Total" "$(_mi_pct "$ma" "$mt")" "of RAM reported usable by kernel"
  if (( st > 0 )); then
    su=$((st - sf))
    printf '%-*s %*s kB  (%*s)\n' "$_sl_lw" "SwapTotal" "$_sl_nw" "$st" "$_sl_hw" "$(_mi_human_kb "$st")"
    printf '%-*s %*s kB  (%*s)  (Swap used: %s kB, %s)\n' "$_sl_lw" "SwapFree" "$_sl_nw" "$sf" "$_sl_hw" "$(_mi_human_kb "$sf")" "$su" "$(_mi_human_kb "$su")"
  else
    printf '%-*s %s\n' "$_sl_lw" "Swap" "none configured (SwapTotal 0)"
  fi
} | boxes -a l -d stone
echo

echo "(PGM) free -h" | boxes -a c -d stone
free -h | boxes -a l -d stone
echo

echo "(PGM) /proc/meminfo - all fields (kB + human)" | boxes -a c -d stone
{
  # Fixed widths: key left, numeric column right, human right (readable in monospace).
  _mi_kw=38
  _mi_nw=18
  _mi_hw=18
  printf -v _mi_ds '%*s' "$_mi_kw" ''
  _mi_ds=${_mi_ds// /-}
  printf -v _mi_dn '%*s' "$_mi_nw" ''
  _mi_dn=${_mi_dn// /-}
  printf -v _mi_dh '%*s' "$_mi_hw" ''
  _mi_dh=${_mi_dh// /-}
  printf '%-*s %*s %*s\n' "$_mi_kw" "Field" "$_mi_nw" "Value (kB)" "$_mi_hw" "Human"
  printf '%-*s %*s %*s\n' "$_mi_kw" "$_mi_ds" "$_mi_nw" "$_mi_dn" "$_mi_hw" "$_mi_dh"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^([^:]+):[[:space:]]+([0-9]+)[[:space:]]+kB[[:space:]]*$ ]]; then
      key="${BASH_REMATCH[1]}"
      kb="${BASH_REMATCH[2]}"
      printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$kb" "$_mi_hw" "$(_mi_human_kb "$kb")"
    elif [[ "$line" =~ ^([^:]+):[[:space:]]+([0-9]+)[[:space:]]*$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$val" "$_mi_hw" "pages"
    elif [[ "$line" =~ ^([^:]+):[[:space:]]+(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      rest="${BASH_REMATCH[2]}"
      printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$rest" "$_mi_hw" "-"
    fi
  done < /proc/meminfo
} | boxes -a l -d stone
echo

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
