#!/bin/bash
# v. 20260718.081500 - end-of-run summary: how many VMs still running

# 2026.07.18 - v. 1.3 - print Total running VMs count at end (and run summary); show (none) when all suspended
# 2026.07.18 - v. 1.2 - Linux vmrun: -T ws + DISPLAY default :0; freeze -vp in PGM_VMRUN_ENC_PASS + env -u TPM_PASS; list without -vp; mapfile + grep '\.vmx$'
# 2026.07.15 - v. 1.1 - visible masked Passphrase: prompt for encrypted VMs (vmrun often shows none)
# 2026.07.15 - v. 1.0 - do not buffer suspend stderr (hides encrypted-VM password prompt); list still quiet
# 2026.07.05 - v. 0.9 - vmrun list only: suppress AppLoader stderr; suspend keeps stderr (VM password prompt)
# 2026.07.05 - v. 0.8 - suppress vmrun AppLoader/libaio stderr noise (like vmrun-check-status.sh)
# 2026.07.05 - v. 0.7 - prompt [a] suspend all remaining; timestamp prefix on prompts
# 2023.05.09 - v. 0.6 - added checking if the script is run on the physical machine
# 2023.02.05 - v. 0.5 - added printing current date and time
# 2023.02.05 - v. 0.4 - added encrypted vm support
# 2023.01.20 - v. 0.3 - added status reporting after starting the vm
# 2023.01.16 - v. 0.2 - small changes to the way things are displayed
# 2023.01.14 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Local-time prefix for interactive prompts, e.g. "(2026.07.05 17:16:00) "

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
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
    *) break ;;
  esac
done

# Local-time prefix for interactive prompts, e.g. "(2026.07.05 17:16:00) "
user_prompt_ts_prefix() {
  printf '(%s) ' "$(date '+%Y.%m.%d %H:%M:%S')"
}

_pgm_vmx_likely_encrypted() {
  [[ -f "$1" ]] || return 1
  if grep -qiE '^encryption\.keySafe[[:space:]]*=' "$1" 2>/dev/null; then
    return 0
  fi
  grep -qiE '^encryptVM\.enabled[[:space:]]*=[[:space:]]*"TRUE"' "$1" 2>/dev/null
}

_pgm_read_password_masked() {
  local -n _pw="$1"
  local prompt="${2:-Passphrase: }"
  local char

  _pw=""
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    echo "(PGM) Not a TTY; cannot read masked passphrase. Set TPM_PASS or use /root/SECRET/vmware-pass.sh" >&2
    return 1
  fi

  printf '%s' "$prompt"
  while true; do
    IFS= read -rs -n 1 char || {
      echo
      return 1
    }
    if [[ "$char" == $'\n' || "$char" == $'\r' || -z "$char" ]]; then
      echo
      break
    fi
    if [[ "$char" == $'\177' || "$char" == $'\b' ]]; then
      if ((${#_pw} > 0)); then
        _pw="${_pw%?}"
        printf '\b \b'
      fi
      continue
    fi
    if [[ "$char" =~ [^[:print:]] ]]; then
      continue
    fi
    _pw+="$char"
    printf '*'
  done
  return 0
}

_pgm_ensure_tpm_pass_for_vmx() {
  local vmx="$1"

  [[ -n "${TPM_PASS:-}" ]] && return 0
  if ! _pgm_vmx_likely_encrypted "$vmx"; then
    return 0
  fi
  echo
  echo "$(user_prompt_ts_prefix)(PGM) This VMX appears encrypted. Enter the encryption passphrase (characters shown as *; Backspace corrects)."
  if ! _pgm_read_password_masked TPM_PASS "Passphrase: "; then
    echo "(PGM) Passphrase input aborted." >&2
    return 1
  fi
  TPM_PASS="${TPM_PASS//$'\r'/}"
  PGM_VMRUN_ENC_PASS="${TPM_PASS}"
  if [[ -z "${TPM_PASS}" ]]; then
    echo "(PGM) Empty passphrase — vmrun may still wait on stdin without a visible prompt." >&2
  fi
  return 0
}

check_if_installed virt-what

virt_what_out=$(virt-what 2>/dev/null) || true
if [[ -n "${virt_what_out//[[:space:]]/}" ]]; then
  vw_report="${virt_what_out//$'\n'/, }"
  vw_report="${vw_report%, }"
  echo
  echo "(PGM) host is NOT a physical machine (virt-what: ${vw_report}) ... exiting ..."
  echo
  exit 1
fi

export DISPLAY=

if [[ -f /root/SECRET/vmware-pass.sh ]]; then
  # shellcheck source=/dev/null
  . /root/SECRET/vmware-pass.sh
  [[ -n "${TPM_PASS:-}" ]] && TPM_PASS="${TPM_PASS//$'\r'/}"
fi

if ! type -fP vmrun &>/dev/null; then
  echo
  echo "(PGM) I can't find vmrun utility... exiting ..."
  echo
  exit 1
fi

VMRUN_PREFIX=(vmrun)
if [[ "$(uname -s)" == Linux && -z "${VMRUN_NO_WS:-}" ]]; then
  VMRUN_PREFIX=(vmrun -T ws)
fi

_pgm_vmrun_enc_display() {
  printf '%s' "${PGM_VMRUN_DISPLAY:-${VMRUN_DISPLAY:-${DISPLAY:-:0}}}"
}

PGM_VMRUN_ENC_PASS="${TPM_PASS-}"
_pgm_ed="$(_pgm_vmrun_enc_display)"

# vmrun list: suppress AppLoader/libaio noise; running VM paths do not need -vp.
_pgm_vmrun_list() {
  "${VMRUN_PREFIX[@]}" list 2>/dev/null
}

_pgm_running_vmx_lines() {
  _pgm_vmrun_list | grep -E '\.vmx$' | sort -u
}

# Fills the array named by $1 with running .vmx paths.
_pgm_collect_running_vmx() {
  local -n _paths_ref="$1"
  mapfile -t _paths_ref < <(_pgm_running_vmx_lines)
}

_pgm_show_running_vms_block() {
  local heading="$1"
  local -n _vms_ref="$2"
  local count=${#_vms_ref[@]}

  echo
  echo "====================  ${heading}  ========================"
  echo "(PGM) Total running VMs: ${count}"
  if (( count == 0 )); then
    echo "(PGM) (none)"
  else
    printf '%s\n' "${_vms_ref[@]}" | boxes -s 40x5 -a c 2>/dev/null || true
    printf '%s\n' "${_vms_ref[@]}"
  fi
  echo
}

_pgm_vmrun_suspend() {
  local vmx="$1"
  local rc=0

  if _pgm_vmx_likely_encrypted "$vmx" && [[ -n "${PGM_VMRUN_ENC_PASS:-}" ]]; then
    /bin/env -u TPM_PASS DISPLAY="$_pgm_ed" "${VMRUN_PREFIX[@]}" -vp "$PGM_VMRUN_ENC_PASS" suspend "$vmx" nogui
    rc=$?
  else
    "${VMRUN_PREFIX[@]}" suspend "$vmx" nogui
    rc=$?
  fi
  return "$rc"
}

_pgm_collect_running_vmx _running_vms
_initial_running_count=${#_running_vms[@]}
_pgm_show_running_vms_block "RUNNING VMs AT START" _running_vms

_suspend_ok=0
_suspend_fail=0
suspend_all=0

for p in "${_running_vms[@]}"; do
  if [[ ! -f "$p" ]]; then
    echo "(PGM) skipping — not a .vmx file: $p" >&2
    continue
  fi
  do_suspend=0

  if (( suspend_all == 1 )); then
    do_suspend=1
  else
    echo
    echo -n "$(user_prompt_ts_prefix)Do you want to SUSPEND $p [y/N/a/q]: "
    input_from_user=""
    read -t 300 -n 1 input_from_user
    echo
    case "${input_from_user}" in
      a|A)
        suspend_all=1
        do_suspend=1
        ;;
      y|Y)
        do_suspend=1
        ;;
      q|Q)
        echo
        exit 1
        ;;
      *)
        do_suspend=0
        ;;
    esac
  fi

  if (( do_suspend == 1 )); then
    if ! _pgm_ensure_tpm_pass_for_vmx "$p"; then
      echo ; echo "(PGM) skipping suspend — no passphrase for encrypted VM"; echo
      continue
    fi
    PGM_VMRUN_ENC_PASS="${TPM_PASS-}"
    _pgm_ed="$(_pgm_vmrun_enc_display)"
    if _pgm_vmx_likely_encrypted "$p" && [[ -n "${PGM_VMRUN_ENC_PASS:-}" ]]; then
      echo "(PGM) suspending encrypted VM with -vp (passphrase from TPM_PASS / earlier prompt)"
    fi
    echo "* * * suspending $p (PGM) * * *"
    _pgm_vmrun_suspend "$p"
    if (( $? == 0 )); then
      ((++_suspend_ok))
      echo ; echo "(PGM) vmrun finished SUCCESSFULLY"; echo
    else
      ((++_suspend_fail))
      echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    fi
  fi
  sleep 0.5 ;
done;

_pgm_collect_running_vmx _still_running_vms
_still_running_count=${#_still_running_vms[@]}
_pgm_show_running_vms_block "RUNNING VMs STILL RUNNING" _still_running_vms

echo "(PGM) Run summary: ${_initial_running_count} running at start, ${_suspend_ok} suspended successfully, ${_suspend_fail} suspend failed, ${_still_running_count} still running."
echo

. /root/bin/_script_footer.sh
