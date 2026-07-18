#!/bin/bash
# v. 20260718.082000 - English password prompt; track script in github-bin

# 2026.07.18 - v. 1.0 - add to repo; translate Wpisz haslo -> Enter password
# 2026.05.26 - user-facing messages translated from Polish to English
# 202x.xx.xx - v. 0.1 - initial release (nuci7b GNU screen window)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Long-running screen helper: load SSH keys into keychain/ssh-agent after reboot.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay.
EOF
}

HEADER_EXTRA_ARGS=(--no_startup_delay)
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

check_if_installed keychain

klucze=""

if [[ -f "${HOME}/.ssh/id_ed25519_backupy" ]]; then
  klucze="id_ed25519_backupy id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
else
  klucze="id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
fi

if [[ -f "${HOME}/.ssh/id_ed25519_kopiowanie_scp" ]]; then
  klucze="$klucze id_ed25519_kopiowanie_scp"
fi

if [[ -f "${HOME}/.ssh/id_ed25519_nucvm_adminkey" ]]; then
  klucze="$klucze id_ed25519_nucvm_adminkey"
fi

export klucze

expected_key_count=$(echo ${klucze} | wc -w)

echo
echo "(PGM) ssh-keychain-daemon — GNU screen helper on ${HOSTNAME}"
echo "(PGM) Will load ${expected_key_count} key(s): ${klucze}"
echo

while : ; do
  read -r -p "Enter password: " -s PASSWD
  echo

  echo "[$(date '+%Y.%m.%d %H:%M:%S')] (PGM) keychain --nocolor ${klucze}"
  keychain --nocolor ${klucze} 2>&1

  if [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]]; then
    # shellcheck source=/dev/null
    . "${HOME}/.keychain/${HOSTNAME}-sh"
  fi

  keychain --nogui --nocolor -l 2>&1
  echo
  echo "(PGM) sleeping 10 minutes before next cycle (Ctrl-C to stop)..."
  sleep 600
done
