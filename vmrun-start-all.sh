#!/bin/bash

# 2026.07.05 - v. 0.8 - vmrun list only: suppress AppLoader stderr; start keeps stderr (VM password prompt)
# 2026.07.05 - v. 0.7 - suppress vmrun AppLoader/libaio stderr noise (like vmrun-check-status.sh)
# 2026.07.05 - v. 0.6 - prompt [a] start all remaining; timestamp prefix on prompts
# 2023.05.09 - v. 0.5 - added checking if the script is run on the physical machine
# 2023.02.05 - v. 0.4 - added printing current date and time
# 2023.02.05 - v. 0.3 - added encrypted vm support
# 2023.01.20 - v. 0.2 - added status reporting after starting the vm
# 2023.01.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

# Local-time prefix for interactive prompts, e.g. "(2026.07.05 17:16:00) "
user_prompt_ts_prefix() {
  printf '(%s) ' "$(date '+%Y.%m.%d %H:%M:%S')"
}

# vmrun list: harmless AppLoader/libaio on stderr (see vmrun-check-status.sh).
# vmrun start/suspend: keep stderr — encrypted VMs prompt for password there.
_pgm_vmrun_list() {
  if [ -n "${TPM_PASS:-}" ]; then
    vmrun -vp "${TPM_PASS}" list 2>/dev/null
  else
    vmrun list 2>/dev/null
  fi
}

_pgm_vmrun() {
  local tmp_err rc
  tmp_err="$(mktemp "${TMPDIR:-/tmp}/vmrun-start-all.err.XXXXXX")"
  if [ -n "${TPM_PASS:-}" ]; then
    vmrun -vp "${TPM_PASS}" "$@" 2>"$tmp_err"
  else
    vmrun "$@" 2>"$tmp_err"
  fi
  rc=$?
  grep -v -E '^\[AppLoader\]|^An up-to-date "libaio' "$tmp_err" >&2 || true
  rm -f "$tmp_err"
  return $rc
}

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

VM_LOCATIONS="/vmware /vmware-nvme /encrypted/vmware-in-encrypted /mnt/luks-raidsonic /mnt/luks-icybox10/vmware /mnt/luks-buffalo2/vmware"
VM_LOCATIONS="$VM_LOCATIONS /mnt/luks-raid1-A/vmware"

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo 
  exit 1
fi

_pgm_vmrun_list | boxes -s 40x5 -a c
_pgm_vmrun_list
echo;

echo ; echo "All VMs on that host (running and not running):" ; echo 
find $VM_LOCATIONS -type f -name \*vmx 2>/dev/null
echo ; echo 

export OIFS="$IFS"

start_all=0

for p in $VM_LOCATIONS ; do 
  export IFS=$'\n'
  for vm in $(find $p -type f -name "*.vmx" -print 2>/dev/null);do 
    if (( $(_pgm_vmrun_list | grep -v "Total running VMs:" | grep -cF "$vm") != 0 ))  ;then
      echo "(PGM) machine $vm is running so we don't want to start it again...";echo 
      continue
    fi
    echo $vm | boxes -s 40x5 -a c
    ls -ld $vm `dirname $vm`/*lck 2>/dev/null

    do_start=0
    if (( start_all == 1 )); then
      do_start=1
    else
      input_from_user=""
      echo -n "$(user_prompt_ts_prefix)Do you want to START $vm [y/N/a/q]: "
      IFS="$OIFS" read -t 300 -n 1 input_from_user
      echo
      case "${input_from_user}" in
        a|A)
          start_all=1
          do_start=1
          ;;
        y|Y)
          do_start=1
          ;;
        q|Q)
          echo
          exit 1
          ;;
        *)
          do_start=0
          ;;
      esac
    fi

    if (( do_start == 1 )); then
      if [ -d "${vm}.lck" ]; then
        echo "(PGM) removing lck directory as it exists..."
        rm -rfv "${vm}.lck"
      fi
      echo "* * * starting $vm (PGM) * * *";echo 
      _pgm_vmrun start "$vm" nogui
      if (( $? == 0 )); then
        echo ; echo "(PGM) vmrun finished SUCCESSFULLY"; echo
      else
        echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
      fi       
    fi
    echo 
  done
done

echo ; 

_pgm_vmrun_list | boxes -s 40x5 -a c
echo 
_pgm_vmrun_list
echo 

. /root/bin/_script_footer.sh
