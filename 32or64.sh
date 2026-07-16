#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.4 - add --no_startup_delay option (parsed before header)
# 2026.04.22 - v. 0.3 - help/version; validate getconf; show uname -m/s; optional dpkg arch; return_code
# 2023.09.13 - v. 0.2 - added invocation of script_header and script_footer
# 2022.12.02 - v. 0.1 - inicjalna wersja skryptu

print_version_line() {
  local ver=unknown date=
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$ver" "$date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$ver"
  fi
}

show_help() {
  cat <<'EOF'
Usage: 32or64.sh [-h|--help] [-v|--version] [--no_startup_delay]

Prints userspace width from getconf LONG_BIT (typically 32 or 64) and the
kernel-reported machine name from uname -m (e.g. x86_64, aarch64, armv7l).

LONG_BIT is the C "long" size for this ABI, not always the CPU's widest mode.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  --no_startup_delay
                 Skip random startup delay when run non-interactively.
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_line; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) echo "(PGM) Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

return_code=0

if ! type -fP getconf &>/dev/null; then
  echo
  echo "(PGM) getconf not found (install libc-bin or similar)."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

_bits=$(getconf LONG_BIT 2>/dev/null) || _bits=
if [[ -z "$_bits" ]] || ! [[ "$_bits" =~ ^[0-9]+$ ]]; then
  echo
  echo "(PGM) getconf LONG_BIT failed or returned an unexpected value."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

echo
echo "(PGM) Userspace LONG_BIT (typical 32/64-bit ABI): ${_bits}"
echo "(PGM) Machine hardware name (uname -m): $(uname -m)"
echo "(PGM) Operating system (uname -s): $(uname -s)"
if type -fP dpkg &>/dev/null; then
  echo "(PGM) dpkg architecture: $(dpkg --print-architecture 2>/dev/null)"
fi
echo

. /root/bin/_script_footer.sh

exit "${return_code}"
