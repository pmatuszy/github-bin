#!/bin/bash

# 2026.04.22 - v. 0.3 - help/version; validate getconf; show uname -m/s; optional dpkg arch; kod_powrotu
# 2023.09.13 - v. 0.2 - added invocation of script_header and script_footer
# 2022.12.02 - v. 0.1 - inicjalna wersja skryptu

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  cat <<'EOF'
Usage: 32or64.sh [-h|--help] [-v|--version]

Prints userspace width from getconf LONG_BIT (typically 32 or 64) and the
kernel-reported machine name from uname -m (e.g. x86_64, aarch64, armv7l).

LONG_BIT is the C "long" size for this ABI, not always the CPU's widest mode.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
EOF
  exit 0
fi

if [[ "${1:-}" == -v || "${1:-}" == --version ]]; then
  _b_ver=unknown
  _b_date=
  while IFS= read -r _b_line; do
    if [[ "$_b_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
      _b_date="${BASH_REMATCH[1]}"
      _b_ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$_b_date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$_b_ver" "$_b_date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$_b_ver"
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

if ! type -fP getconf &>/dev/null; then
  echo
  echo "(PGM) getconf not found (install libc-bin or similar)."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

_bits=$(getconf LONG_BIT 2>/dev/null) || _bits=
if [[ -z "$_bits" ]] || ! [[ "$_bits" =~ ^[0-9]+$ ]]; then
  echo
  echo "(PGM) getconf LONG_BIT failed or returned an unexpected value."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
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

exit "${kod_powrotu}"
