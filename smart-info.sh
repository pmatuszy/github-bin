#!/bin/bash

# 2023.07.03 - v. 0.6 - bugfix: jd.sh 2> redirection to /dev/null
# 2023.02.10 - v. 0.5 - added check for smartmontools package
# 2023.02.07 - v. 0.4 - added _script_header.sh and _script_footer.sh
# 2023.01.09 - v. 0.3 - interactive session with clear screen, better seagate drive detection
# 2022.12.20 - v. 0.2 - check if any command line arguments were provided...
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed smartctl smartmontools

export disks=""

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, I will run the script against ALL disks found on this systems..."
    echo "searching for disks..."
    disks=$(jd.sh 2>/dev/null |grep Disk |sed 's|:.*||g'|sed 's|Disk ||g')
    sleep 3
else
  disks=$1
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="--info"

export SMARTCTL_BIN=$(type -fP smartctl)

for p in $disks ; do 
  if (( script_is_run_interactively ));then
     clear
  fi
  echo;echo
  echo $p | boxes -s 40x5 -a c ; echo 

  $SMARTCTL_BIN  --info $p 2>&1 > /dev/null
  if (( $? == 1 ));then 
    DEVICE_TYPE='-d sat'
  fi

  $SMARTCTL_BIN $DEVICE_TYPE --info $p 2>&1 > /dev/null
  if (( $? == 1 ));then 
    echo  ; echo "I don't know which device type (-d), so I am quitting" ; echo ; echo exit 1
    exit 1
  fi

  $SMARTCTL_BIN $DEVICE_TYPE --info $p 2>&1 > /dev/null
  if (( $? == 2 ));then
    echo  ; echo "No such a device, I am exiting " ; echo
    # exit 2
    if (( script_is_run_interactively ));then
       echo "Press <ENTER> to continue or q/Q to quit"
       input_from_user=""
       read -t 300 -n 1 input_from_user
       if [ "${input_from_user}" == 'q' -o  $"{input_from_user}" == 'Q' ]; then
         echo
         exit
       fi
    fi
    continue
  fi

  czy_seagate=$($SMARTCTL_BIN  $DEVICE_TYPE --info $p| egrep -i 'seagate|ST18000NM000J'| wc -l)
  if (( $czy_seagate > 0 ));then
    VENDOR_ATTRIBUTE="-v 1,raw48:54 -v 7,raw48:54 -v 187,raw48:54  -v 188,raw48:54 -v 195,raw48:54"
    echo ; echo "* * * * * * This is Seagate drive (PGM) * * * * * *" ; echo 
  fi 
  $SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $p
  if (( script_is_run_interactively ));then
     echo "Press <ENTER> to continue or q/Q to quit"
     input_from_user=""
     read -t 300 -n 1 input_from_user
     if [ "${input_from_user}" == 'q' -o  $"{input_from_user}" == 'Q' ]; then
       echo
       exit
     fi
  fi
done

. /root/bin/_script_footer.sh
