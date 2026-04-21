#!/bin/bash

# 2026.04.21 - v. 0.7 - summary box: fixed column for trailing notes (align with MemTotal line)
# 2026.04.21 - v. 0.6 - summary: used vs cache (Total-Avail, AnonPages, Cached, Buffers)
# 2026.04.21 - v. 0.5 - optional -p/--page pauses; -c/--chunk or MEM_INFO_CHUNK_LINES splits meminfo table
# 2026.04.21 - v. 0.4 - aligned summary box (MemTotal/MemAvailable/...) with printf columns
# 2026.04.21 - v. 0.3 - aligned /proc/meminfo table; bare integers (e.g. HugePages_*) get 3 columns
# 2026.04.21 - v. 0.2 - ASCII-only user-visible text (avoid ??? in non-UTF-8 / boxes)
# 2026.04.21 - v. 0.1 - RAM report: /proc/meminfo + free -h, boxed sections; help/version

_mi_page=0
_mi_chunk=${MEM_INFO_CHUNK_LINES:-0}
_show_help=0
_show_ver=0

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      _show_help=1
      shift
      ;;
    -v|--version)
      _show_ver=1
      shift
      ;;
    -p|--page)
      _mi_page=1
      shift
      ;;
    -c|--chunk)
      if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "(PGM) --chunk requires a non-negative integer (e.g. --chunk 25)" >&2
        exit 1
      fi
      _mi_chunk=$2
      shift 2
      ;;
    *)
      echo "(PGM) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

[[ "${MEM_INFO_PAGE:-0}" == 1 ]] && _mi_page=1

if ((_show_help)); then
  cat <<'EOF'
Usage: mem-info.sh [-h|--help] [-v|--version] [-p|--page] [-c N|--chunk N]

Print a readable RAM report for the local Linux system: summary (with the
kernel's MemAvailable estimate, rough "used" vs page cache), full free(1)
output, and every field from /proc/meminfo with kB and human-readable columns.

MemAvailable is usually the best "how much RAM can I use?" number; MemFree
ignores reclaimable cache. The summary also shows MemTotal-MemAvailable
(rough "in use" vs MemAvailable), AnonPages (anonymous program memory),
Cached (file cache), and Buffers.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  -p, --page     Pause between sections (and between meminfo chunks) on an
                 interactive terminal; press Enter to continue. Reads from
                 /dev/tty so piping stdout still works.
  -c N, --chunk N
                 Show at most N meminfo rows per boxed table (header repeated
                 each chunk). N=0 means one box with all rows (default).

Environment:
  MEM_INFO_PAGE         If 1, same as -p.
  MEM_INFO_CHUNK_LINES  Default chunk size before -c overrides (default: 0 = all).

Examples:
  mem-info.sh
  mem-info.sh | less -S
  mem-info.sh -p
      Pause after each section when stdout is a tty.
  mem-info.sh -c 20
      Split /proc/meminfo into boxes of 20 fields (easier to read in screen).
  MEM_INFO_CHUNK_LINES=25 mem-info.sh -p
      Combine chunking with paging.
EOF
  exit 0
fi

if ((_show_ver)); then
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

. /root/bin/_script_header.sh

kod_powrotu=0

_mi_pause_if_needed() {
  if (( _mi_page )) && [[ -t 1 ]] && [[ -r /dev/tty ]]; then
    read -r -p "(PGM) Press Enter for next section... " _ < /dev/tty || true
    echo
  fi
}

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

_mi_print_meminfo_header() {
  local _mi_kw=38 _mi_nw=18 _mi_hw=18
  printf -v _mi_ds '%*s' "$_mi_kw" ''
  _mi_ds=${_mi_ds// /-}
  printf -v _mi_dn '%*s' "$_mi_nw" ''
  _mi_dn=${_mi_dn// /-}
  printf -v _mi_dh '%*s' "$_mi_hw" ''
  _mi_dh=${_mi_dh// /-}
  printf '%-*s %*s %*s\n' "$_mi_kw" "Field" "$_mi_nw" "Value (kB)" "$_mi_hw" "Human"
  printf '%-*s %*s %*s\n' "$_mi_kw" "$_mi_ds" "$_mi_nw" "$_mi_dn" "$_mi_hw" "$_mi_dh"
}

_mi_print_meminfo_line() {
  local line=$1
  local _mi_kw=38 _mi_nw=18 _mi_hw=18
  [[ -z "$line" ]] && return
  if [[ "$line" =~ ^([^:]+):[[:space:]]+([0-9]+)[[:space:]]+kB[[:space:]]*$ ]]; then
    local key="${BASH_REMATCH[1]}"
    local kb="${BASH_REMATCH[2]}"
    printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$kb" "$_mi_hw" "$(_mi_human_kb "$kb")"
  elif [[ "$line" =~ ^([^:]+):[[:space:]]+([0-9]+)[[:space:]]*$ ]]; then
    local key="${BASH_REMATCH[1]}"
    local val="${BASH_REMATCH[2]}"
    printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$val" "$_mi_hw" "pages"
  elif [[ "$line" =~ ^([^:]+):[[:space:]]+(.*)$ ]]; then
    local key="${BASH_REMATCH[1]}"
    local rest="${BASH_REMATCH[2]}"
    printf '%-*s %*s %*s\n' "$_mi_kw" "$key" "$_mi_nw" "$rest" "$_mi_hw" "-"
  fi
}

echo
echo "(PGM) Memory (RAM) report - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S %Z')" | boxes -a c -d stone
echo
_mi_pause_if_needed

mt=$(_mi_kb MemTotal) || mt=0
ma=$(_mi_kb MemAvailable) || ma=0
mf=$(_mi_kb MemFree) || mf=0
st=$(_mi_kb SwapTotal) || st=0
sf=$(_mi_kb SwapFree) || sf=0
_mi_anon=$(_mi_kb AnonPages) || _mi_anon=0
_mi_cached=$(_mi_kb Cached) || _mi_cached=0
_mi_buffers=$(_mi_kb Buffers) || _mi_buffers=0
_mi_used_na=$((mt - ma))
((_mi_used_na < 0)) && _mi_used_na=0

# Summary layout (monospace): label(22) + sp + kB(12) + " kB  (" + human(14) + ")  " => notes start at column 59.
_mi_sl_lw=22
_mi_sl_nw=12
_mi_sl_hw=14
_mi_sl_note_col=59

_mi_sl_pad_to_note() {
  local printed=$1
  local pad=$((_mi_sl_note_col - 1 - printed))
  ((pad < 0)) && pad=0
  printf '%*s' "$pad" ''
}

{
  _mi_line=''
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "MemTotal" "$_mi_sl_nw" "$mt" "$_mi_sl_hw" "$(_mi_human_kb "$mt")" "")
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "MemAvailable" "$_mi_sl_nw" "$ma" "$_mi_sl_hw" "$(_mi_human_kb "$ma")" '<- practical "free" estimate')
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "MemFree" "$_mi_sl_nw" "$mf" "$_mi_sl_hw" "$(_mi_human_kb "$mf")" '(unused; cache not counted)')
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "Used (approx.)" "$_mi_sl_nw" "$_mi_used_na" "$_mi_sl_hw" "$(_mi_human_kb "$_mi_used_na")" '(MemTotal-MemAvailable; not in Avail)')
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "AnonPages" "$_mi_sl_nw" "$_mi_anon" "$_mi_sl_hw" "$(_mi_human_kb "$_mi_anon")" '(anonymous RAM: apps, stacks, etc.)')
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "Cached" "$_mi_sl_nw" "$_mi_cached" "$_mi_sl_hw" "$(_mi_human_kb "$_mi_cached")" '(file page cache; reclaimable)')
  echo "$_mi_line"
  _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "Buffers" "$_mi_sl_nw" "$_mi_buffers" "$_mi_sl_hw" "$(_mi_human_kb "$_mi_buffers")" '(block device buffers)')
  echo "$_mi_line"
  _mi_pt="$(_mi_pct "$ma" "$mt")"
  _mi_prefix=$(printf '%-*s %*s' "$_mi_sl_lw" "Available/Total" "$_mi_sl_nw" "$_mi_pt")
  _mi_p=${#_mi_prefix}
  printf '%s' "$_mi_prefix"
  _mi_sl_pad_to_note "$_mi_p"
  echo 'of RAM reported usable by kernel'
  if (( st > 0 )); then
    su=$((st - sf))
    _mi_line=$(printf '%-*s %*s kB  (%*s)  %s' "$_mi_sl_lw" "SwapTotal" "$_mi_sl_nw" "$st" "$_mi_sl_hw" "$(_mi_human_kb "$st")" "")
    echo "$_mi_line"
    _mi_line=$(printf '%-*s %*s kB  (%*s)  (Swap used: %s kB, %s)' "$_mi_sl_lw" "SwapFree" "$_mi_sl_nw" "$sf" "$_mi_sl_hw" "$(_mi_human_kb "$sf")" "$su" "$(_mi_human_kb "$su")")
    echo "$_mi_line"
  else
    _mi_prefix=$(printf '%-*s %*s' "$_mi_sl_lw" "Swap" "$_mi_sl_nw" "")
    _mi_p=${#_mi_prefix}
    printf '%s' "$_mi_prefix"
    _mi_sl_pad_to_note "$_mi_p"
    echo 'none configured (SwapTotal 0)'
  fi
} | boxes -a l -d stone
echo
_mi_pause_if_needed

echo "(PGM) free -h" | boxes -a c -d stone
free -h | boxes -a l -d stone
echo
_mi_pause_if_needed

mapfile -t _mi_memlines < /proc/meminfo
_mi_nonempty=()
for _mi_ln in "${_mi_memlines[@]}"; do
  [[ -n "$_mi_ln" ]] && _mi_nonempty+=("$_mi_ln")
done
_mi_total=${#_mi_nonempty[@]}
_mi_step=$_mi_chunk
if (( _mi_step <= 0 || _mi_step > _mi_total )); then
  _mi_step=$_mi_total
fi

for (( _mi_i = 0; _mi_i < _mi_total; )); do
  _mi_end=$((_mi_i + _mi_step))
  ((_mi_end > _mi_total)) && _mi_end=$_mi_total
  if (( _mi_total == _mi_step )); then
    _mi_title="(PGM) /proc/meminfo - all fields (kB + human)"
  else
    _mi_title="(PGM) /proc/meminfo - fields $((_mi_i + 1))-${_mi_end} of ${_mi_total} (kB + human)"
  fi
  echo "$_mi_title" | boxes -a c -d stone
  {
    _mi_print_meminfo_header
    for ((_mi_j = _mi_i; _mi_j < _mi_end; _mi_j++)); do
      _mi_print_meminfo_line "${_mi_nonempty[_mi_j]}"
    done
  } | boxes -a l -d stone
  echo
  _mi_i=$_mi_end
  ((_mi_i < _mi_total)) && _mi_pause_if_needed
done

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
