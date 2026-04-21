#!/bin/bash

# 2026.04.21 - v. 0.8 - disk array + "$@"; quoting/redirects; grep -E; fix q/Q typo; no Enter after last disk; reset -d per disk
# 2023.09.14 - v. 0.7 - small change - if # of args = 1 then there is no prompt at the end of the script
# 2023.07.03 - v. 0.6 - bugfix: jd.sh 2> redirection to /dev/null
# 2023.02.10 - v. 0.5 - added check for smartmontools package
# 2023.02.07 - v. 0.4 - added _script_header.sh and _script_footer.sh
# 2023.01.09 - v. 0.3 - interactive session with clear screen, better seagate drive detection
# 2022.12.20 - v. 0.2 - check if any command line arguments were provided...
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed smartctl smartmontools

declare -a disk_array

if [ $# -eq 0 ]; then
    echo ; echo ; echo "No arguments supplied, I will run the script against ALL disks found on this systems..."
    echo "searching for disks..."
    mapfile -t disk_array < <(jd.sh 2>/dev/null | grep Disk | sed 's|:.*||g' | sed 's|Disk ||g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    sleep 3
else
    disk_array=("$@")
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="--info"

export SMARTCTL_BIN=$(type -fP smartctl)

nonempty_disk_count=0
for _d in "${disk_array[@]}"; do
  [[ -n "$_d" ]] && ((nonempty_disk_count++))
done
disk_index=0

for p in "${disk_array[@]}"; do
  [[ -n "$p" ]] || continue
  ((disk_index++))
  DEVICE_TYPE=""
  VENDOR_ATTRIBUTE=""

  if (( script_is_run_interactively ));then
     clear
  fi
  echo;echo
  echo "$p" | boxes -s 40x5 -a c ; echo

  $SMARTCTL_BIN --info "$p" >/dev/null 2>&1
  if (( $? == 1 ));then
    DEVICE_TYPE='-d sat'
  fi

  $SMARTCTL_BIN $DEVICE_TYPE --info "$p" >/dev/null 2>&1
  if (( $? == 1 ));then
    echo  ; echo "I don't know which device type (-d), so I am quitting" ; echo
    exit 1
  fi

  $SMARTCTL_BIN $DEVICE_TYPE --info "$p" >/dev/null 2>&1
  if (( $? == 2 ));then
    echo  ; echo "No such a device, I am exiting " ; echo
    if (( script_is_run_interactively )) && (( disk_index < nonempty_disk_count )); then
       echo "Press <ENTER> to continue or q/Q to quit"
       input_from_user=""
       read -t 300 -n 1 input_from_user
       if [[ "${input_from_user}" == [qQ] ]]; then
         echo
         exit
       fi
    fi
    continue
  fi

  czy_seagate=$($SMARTCTL_BIN $DEVICE_TYPE --info "$p" | grep -Ei 'seagate|ST18000NM000J' | wc -l)
  if (( $czy_seagate > 0 ));then
    VENDOR_ATTRIBUTE="-v 1,raw48:54 -v 7,raw48:54 -v 187,raw48:54  -v 188,raw48:54 -v 195,raw48:54"
    echo ; echo "* * * * * * This is Seagate drive (PGM) * * * * * *" ; echo
  fi
  $SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND "$p"

  if (( script_is_run_interactively )) && (( $# != 1 )) && (( disk_index < nonempty_disk_count )); then
     echo "Press <ENTER> to continue or q/Q to quit"
     input_from_user=""
     read -t 300 -n 1 input_from_user
     if [[ "${input_from_user}" == [qQ] ]]; then
       echo
       exit
     fi
  fi

done

. /root/bin/_script_footer.sh
