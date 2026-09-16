#!/bin/bash
# v. 20260916.111800 - load local keys once at startup; the loop now only refreshes the remote hosts
# v. 20260916.110900 - each cycle also runs ssh-keychain.sh on hosts from ssh-keychain-hosts.txt (ssh timeouts)
# v. 20260909.201114 - ask passphrase once; reuse via SSH_ASKPASS in the loop (no X11)
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260718.082000 - English password prompt; track script in github-bin

# 2026.07.18 - v. 1.0 - add to repo; translate Wpisz haslo -> Enter password
# 2026.05.26 - user-facing messages translated from Polish to English
# 202x.xx.xx - v. 0.1 - initial release (nuci7b GNU screen window)
#
# ssh-keychain-daemon.sh
#
# GNU screen helper: load SSH keys into keychain/ssh-agent. Prompts for the
# passphrase once and loads the local keys once, at startup. After that it loops
# every 10 minutes running /root/bin/ssh-keychain.sh over ssh on each host listed
# in ssh-keychain-hosts.txt; unreachable hosts are skipped after a timeout.
# A private SSH_ASKPASS helper supplies the saved passphrase; DISPLAY is a
# dummy so ssh-add never opens X11 ssh-askpass.
# Do not pass --nogui to the add keychain call: 2.8.5 then unsets SSH_ASKPASS
# and ssh-add prompts on the TTY whenever a key is missing.

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Long-running screen helper: load SSH keys into keychain/ssh-agent after reboot.
Asks for the key passphrase once and loads the local keys once, at startup.

It then loops every SSH_KEYCHAIN_DAEMON_SLEEP seconds, each cycle running
/root/bin/ssh-keychain.sh over ssh on every host from the host list file (one
host or user@host per line, # comments and blank lines are ignored, file re-read
every cycle). Hosts that do not answer within SSH_KEYCHAIN_CONNECT_TIMEOUT
seconds are logged and skipped; the loop keeps going regardless of what a remote
run returns.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  --no_startup_delay   Skip random startup delay.

Environment:
  SSH_KEYCHAIN_DAEMON_SLEEP     Seconds between cycles (default: 600).
  SSH_KEYCHAIN_DISPLAY          DISPLAY for keychain's askpass path (default: dummy:0).
  SSH_KEYCHAIN_HOSTS_FILE       Host list (default: /root/bin/ssh-keychain-hosts.txt).
  SSH_KEYCHAIN_REMOTE_CMD       Command run on each host
                                (default: /root/bin/ssh-keychain.sh --no_startup_delay batch).
  SSH_KEYCHAIN_CONNECT_TIMEOUT  ssh ConnectTimeout in seconds (default: 20).
  SSH_KEYCHAIN_REMOTE_TIMEOUT   Hard limit for one remote run in seconds (default: 180).
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
    --history) print_script_history; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

check_if_installed keychain
check_if_installed ssh openssh-client
check_if_installed timeout coreutils

SLEEP_SEC="${SSH_KEYCHAIN_DAEMON_SLEEP:-600}"
HOSTS_FILE="${SSH_KEYCHAIN_HOSTS_FILE:-/root/bin/ssh-keychain-hosts.txt}"
# Both flags are needed: ssh-keychain.sh sources _script_header.sh twice, and each
# source adds a random delay of up to MAX_RANDOM_DELAY_IN_SEC when there is no tty.
REMOTE_CMD="${SSH_KEYCHAIN_REMOTE_CMD:-/root/bin/ssh-keychain.sh --no_startup_delay batch}"
CONNECT_TIMEOUT="${SSH_KEYCHAIN_CONNECT_TIMEOUT:-20}"
REMOTE_TIMEOUT="${SSH_KEYCHAIN_REMOTE_TIMEOUT:-180}"
ASKPASS_FILE=""
PASSWD=""

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

skd_cleanup() {
  if [[ -n "${ASKPASS_FILE}" && -f "${ASKPASS_FILE}" ]]; then
    rm -f -- "${ASKPASS_FILE}"
  fi
  unset PASSWD SSH_ASKPASS SSH_ASKPASS_REQUIRE
}

trap skd_cleanup EXIT

skd_read_host_list() {
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n "${line}" ]] && printf '%s\n' "${line}"
  done < "$1"
}

skd_run_remote() {
  local host="$1" rc

  echo "[$(date '+%Y.%m.%d %H:%M:%S')] (PGM) ${host}: ${REMOTE_CMD}"
  # env -u: our SSH_ASKPASS helper prints the key passphrase, so ssh must never be
  # able to use it to answer a remote password prompt. BatchMode=yes on top of that.
  timeout --kill-after=10 "${REMOTE_TIMEOUT}" \
    env -u SSH_ASKPASS -u SSH_ASKPASS_REQUIRE -u DISPLAY -u PASSWD \
      ssh -n -T -o BatchMode=yes -o ConnectTimeout="${CONNECT_TIMEOUT}" \
             -o ServerAliveInterval=10 -o ServerAliveCountMax=3 \
             "${host}" "${REMOTE_CMD}" 2>&1 | sed "s/^/    [${host}] /"
  rc=${PIPESTATUS[0]}

  case ${rc} in
    0)       echo "    [${host}] (PGM) OK" ;;
    124|137) echo "    [${host}] (PGM) TIMEOUT — killed after ${REMOTE_TIMEOUT}s (rc=${rc})" ;;
    255)     echo "    [${host}] (PGM) ssh connection FAILED (rc=255) — host down, key or BatchMode problem" ;;
    *)       echo "    [${host}] (PGM) remote script reported problems (rc=${rc})" ;;
  esac
}

skd_remote_cycle() {
  local -a hosts=()
  local host

  if [[ ! -r "${HOSTS_FILE}" ]]; then
    echo "(PGM) host list ${HOSTS_FILE} not readable — skipping remote refresh"
    echo
    return 0
  fi

  mapfile -t hosts < <(skd_read_host_list "${HOSTS_FILE}")

  if (( ${#hosts[@]} == 0 )); then
    echo "(PGM) host list ${HOSTS_FILE} contains no hosts — skipping remote refresh"
    echo
    return 0
  fi

  echo "(PGM) remote refresh on ${#hosts[@]} host(s) from ${HOSTS_FILE}"
  for host in "${hosts[@]}"; do
    skd_run_remote "${host}"
  done
  echo
}

echo
echo "(PGM) ssh-keychain-daemon — GNU screen helper on ${HOSTNAME}"
echo "(PGM) Will load ${expected_key_count} key(s): ${klucze}"
echo "(PGM) Remote refresh each cycle from ${HOSTS_FILE} (connect timeout ${CONNECT_TIMEOUT}s)"
echo

if [[ ! -t 0 ]]; then
  echo "(PGM) No TTY — cannot read the passphrase. Run this in screen or a terminal."
  exit 1
fi

read -r -p "Enter password: " -s PASSWD
echo
echo
export PASSWD

askpass_dir="/dev/shm"
[[ -d "${askpass_dir}" && -w "${askpass_dir}" ]] || askpass_dir="${TMPDIR:-/tmp}"
ASKPASS_FILE=$(mktemp "${askpass_dir}/ssh-keychain-askpass.XXXXXX")
chmod 700 "${ASKPASS_FILE}"
cat > "${ASKPASS_FILE}" << 'EOF'
#!/bin/sh
printf '%s\n' "${PASSWD-}"
EOF

# keychain 2.8.5 uses SSH_ASKPASS only when BOTH SSH_ASKPASS and DISPLAY are set
# (and --nogui is not used). Dummy DISPLAY avoids a real X11 ssh-askpass.
export SSH_ASKPASS="${ASKPASS_FILE}"
export SSH_ASKPASS_REQUIRE=force
export DISPLAY="${SSH_KEYCHAIN_DISPLAY:-dummy:0}"

echo "[$(date '+%Y.%m.%d %H:%M:%S')] (PGM) keychain --nocolor --agents ssh ${klucze}"
# Do not pass --nogui: that unsets SSH_ASKPASS and forces a TTY prompt.
keychain --nocolor --agents ssh ${klucze} 2>&1

if [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]]; then
  # shellcheck source=/dev/null
  . "${HOME}/.keychain/${HOSTNAME}-sh"
fi

keychain --nogui --nocolor -l 2>&1
echo

while : ; do
  skd_remote_cycle

  if (( SLEEP_SEC == 600 )); then
    echo "(PGM) sleeping 10 minutes before next cycle (Ctrl-C to stop)..."
  else
    echo "(PGM) sleeping ${SLEEP_SEC}s before next cycle (Ctrl-C to stop)..."
  fi
  sleep "${SLEEP_SEC}"
done
