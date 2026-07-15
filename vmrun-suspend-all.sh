#!/bin/bash

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

. /root/bin/_script_header.sh

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
  if [[ -z "${TPM_PASS}" ]]; then
    echo "(PGM) Empty passphrase — vmrun may still wait on stdin without a visible prompt." >&2
  fi
  return 0
}

# vmrun list: suppress AppLoader/libaio noise. Suspend uses -vp when TPM_PASS is set.
_pgm_vmrun_list() {
  if [ -n "${TPM_PASS:-}" ]; then
    vmrun -vp "${TPM_PASS}" list 2>/dev/null
  else
    vmrun list 2>/dev/null
  fi
}

_pgm_vmrun() {
  if [ -n "${TPM_PASS:-}" ]; then
    vmrun -vp "${TPM_PASS}" "$@"
  else
    vmrun "$@"
  fi
}

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo
  exit 1
fi

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  # shellcheck source=/dev/null
  . /root/SECRET/vmware-pass.sh
  [[ -n "${TPM_PASS:-}" ]] && TPM_PASS="${TPM_PASS//$'\r'/}"
fi

_pgm_vmrun_list | boxes -s 40x5 -a c
echo;
_pgm_vmrun_list
echo

export IFS=$'\n'

suspend_all=0

for p in `$(_pgm_vmrun_list | grep vmx)`;do
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
    if _pgm_vmx_likely_encrypted "$p" && [[ -n "${TPM_PASS:-}" ]]; then
      echo "(PGM) suspending encrypted VM with -vp (passphrase from TPM_PASS / earlier prompt)"
    fi
    echo "* * * suspending $p (PGM) * * *"
    _pgm_vmrun suspend "$p" nogui
    if (( $? == 0 )); then
      echo ; echo "(PGM) vmrun finished SUCCESSFULLY"; echo
    else
      echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    fi
  fi
  sleep 0.5 ;
done;

echo ;

_pgm_vmrun_list | boxes -s 40x5 -a c
echo
_pgm_vmrun_list
echo

. /root/bin/_script_footer.sh
