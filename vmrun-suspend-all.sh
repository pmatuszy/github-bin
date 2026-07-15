#!/bin/bash

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

# vmrun list: suppress AppLoader/libaio noise. Suspend keeps stderr live for password prompts.
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
  . /root/SECRET/vmware-pass.sh
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
