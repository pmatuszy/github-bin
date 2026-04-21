#!/bin/bash

# 2026.04.22 - v. 0.1 - curl timeouts, IPv4/IPv6, fallbacks, --raw (no header), PGM output otherwise

_show_help=0
_show_ver=0
_ip_curl_family=(-4)
_raw=0

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
    -4)
      _ip_curl_family=(-4)
      shift
      ;;
    -6)
      _ip_curl_family=(-6)
      shift
      ;;
    --raw)
      _raw=1
      shift
      ;;
    *)
      echo "(PGM) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

if ((_show_help)); then
  cat <<'EOF'
Usage: public-ip-address.sh [-h|--help] [-v|--version] [-4|-6] [--raw]

Print this host's public IP using HTTPS endpoints (tries several if one fails).

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  -4             Use IPv4 only (default).
  -6             Use IPv6 only.
  --raw          Print only the address to stdout (no header/footer); for scripts.

Requires curl. Each attempt uses --max-time 10. If both -4 and -6 are given,
the last one wins.
EOF
  exit 0
fi

if ((_show_ver)); then
  _ip_ver=unknown
  _ip_date=
  while IFS= read -r _ip_line; do
    if [[ "$_ip_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
      _ip_date="${BASH_REMATCH[1]}"
      _ip_ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$_ip_date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$_ip_ver" "$_ip_date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$_ip_ver"
  fi
  exit 0
fi

_ip_urls=(
  'https://checkip.amazonaws.com'
  'https://api.ipify.org'
  'https://ifconfig.me/ip'
  'https://icanhazip.com'
)

_ip_fetch() {
  _ip_out=
  for _ip_u in "${_ip_urls[@]}"; do
    _ip_out=$(curl -fsS --max-time 10 "${_ip_curl_family[@]}" "$_ip_u" 2>/dev/null | tr -d '\r' | head -n1)
    _ip_out="${_ip_out//[[:space:]]/}"
    [[ -n "$_ip_out" ]] && return 0
  done
  return 1
}

if ((_raw)); then
  if ! type -fP curl &>/dev/null; then
    echo "(PGM) curl not found; install curl." >&2
    exit 1
  fi
  if ! _ip_fetch; then
    echo "(PGM) Could not get public IP (all endpoints failed or timed out)." >&2
    exit 1
  fi
  printf '%s\n' "$_ip_out"
  exit 0
fi

. /root/bin/_script_header.sh

kod_powrotu=1

if ! type -fP curl &>/dev/null; then
  echo
  echo "(PGM) curl not found; install curl to use this script."
  echo
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

if ! _ip_fetch; then
  echo
  echo "(PGM) Could not get public IP (all endpoints failed or timed out)."
  echo
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

kod_powrotu=0

if [[ "${_ip_curl_family[*]}" == -6 ]]; then
  echo "(PGM) Public IPv6: ${_ip_out}"
else
  echo "(PGM) Public IPv4: ${_ip_out}"
fi
echo

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
