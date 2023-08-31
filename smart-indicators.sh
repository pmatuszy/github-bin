#!/bin/bash

# 2023.08.31 - v. 0.7 - bugfix: poweronhours detection for SSD 
# 2023.07.03 - v. 0.6 - bugfix: last_short_offline_test, last_extended_offline_test, last_conveyance_offline_test calculation
# 2023.03.21 - v. 0.7 - bugfix - the whole section of the footer about tests was missing and test time variables were NOT initiated
# 2023.02.10 - v. 0.6 - added check for smartmontools package
# 2023.02.07 - v. 0.6 - added _script_header.sh and _script_footer.sh
# 2023.01.11 - v. 0.5 - prompt for a new page is only displayed if there are no arguments on the command line
# 2023.01.10 - v. 0.4 - added printing time with Linux units utility
# 2023.01.09 - v. 0.3 - interactive session with clear screen, added power on hours calculations
# 2023.01.05 - v. 0.3 - added detection of ST18000NM000J-2TV103 drives as Seagate ones
# 2022.12.20 - v. 0.2 - now printing info about the disk as well
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed smartctl smartmontools

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, I will run the script against ALL disks found on this systems..."
    echo "searching for disks..."
    disks=$(jd.sh 2>/dev/null |grep Disk |sed 's|:.*||g'|sed 's|Disk ||g')
    sleep 2
else
  disks=$1
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="--info -A "
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
    echo  ; echo "I don't know which device type (-d), so I am quitting" ; echo ; echo exit 1 ; echo 
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

  czy_seagate=$($SMARTCTL_BIN  $DEVICE_TYPE --info $p|egrep -i 'seagate|ST18000NM000J' | wc -l)
  if (( $czy_seagate > 0 ));then
    VENDOR_ATTRIBUTE="-v 1,raw48:54 -v 7,raw48:54 -v 187,raw48:54  -v 188,raw48:54 -v 195,raw48:54"
    echo "* * * * * * This is Seagate drive (PGM) * * * * * *"
  fi

  export power_on_hours=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE -A $p | egrep '^  9' | awk '{print $10}'|sed 's|[hms].*||g' )     # ost sed zostawia tylko 24979 z "24979h+00m+00.000s"
  export last_short_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE --info -l selftest $p | egrep -i 'Short offline|Short captive'|head -1|sed 's|.*% *||g' | awk '{print $1}')
  export last_extended_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE --info -l selftest $p | egrep -i 'Extended offline|Extended captive'|head -1|sed 's|.*% *||g' | awk '{print $1}')
  export last_conveyance_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE --info -l selftest $p | egrep -i 'Conveyance offline|Conveyance captive'|head -1|sed 's|.*% *||g' | awk '{print $1}')

  let last_short_offline_ago=power_on_hours-last_short_offline_test
  let last_extended_offline_ago=power_on_hours-last_extended_offline_test
  let last_conveyance_offline_ago=power_on_hours-last_conveyance_offline_test

  czy_seagate=$($SMARTCTL_BIN  $DEVICE_TYPE --info $p|egrep -i 'seagate|ST18000NM000J' | wc -l)
  if (( $czy_seagate > 0 ));then
    VENDOR_ATTRIBUTE="-v 1,raw48:54 -v 7,raw48:54 -v 187,raw48:54  -v 188,raw48:54 -v 195,raw48:54"
    echo ; echo "* * * * * * This is Seagate drive (PGM) * * * * * *" ; echo 
  fi 
  $SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $p

  echo

  # in case of some SSD there is Power on Hours in form of 'Power On Hours:' or 'Power_On_Hours'
  if (( $($SMARTCTL_BIN $DEVICE_TYPE -x $p 2>/dev/null | egrep -i '^Power.On.Hours' | wc -l) > 0 ));then
    export power_on_hours=$($SMARTCTL_BIN $DEVICE_TYPE -x $p| egrep -i '^Power.On.Hours' | sed 's|.* ||g'|tr -d ',' | sed 's|Hours||g' | sed 's|[hms].*||g' | awk '{print $1}')
  fi

  if [ -z ${power_on_hours:-} ];then   # sometimes there is on power on hours in SMART attribues so I set it to -1
    power_on_hours=-1
  fi

  # if (( $power_on_hours < 1 )) && (( $($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE --info $p|grep -i SSD | wc -l) > 0 ));then
  if (( $($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE --info $p|grep -i SSD | wc -l) > 0 )) && (( ${power_on_hours} < 1 )) ;then
    echo -e "Looks like SSD drive and this one has no POWER ON HOURS S.M.A.R.T. attribute available." |boxes -s 95x5 -a c ; echo
  else
    if (( ${power_on_hours} > 65535 )) ; then
      printf -- '-----> power_on_hours               = %5i hours, %2.2f years (possible wrap around as it is more than 65535 hours.... )' $power_on_hours $(echo "scale=2; $power_on_hours/24/365.25"|bc)
      echo -e " (" $(units "${power_on_hours} hours" time |sed 's|hr .*|hr|g') ")\n"
      echo "RAW values calculation:"
      printf -- '-----> last_short_offline_ago       = %5i hours ago\n'   $last_short_offline_ago
      printf -- '-----> last_extended_offline_test   = %5i hours ago\n'   $last_extended_offline_ago
      printf -- '-----> last_conveyance_offline_test = %5i hours ago\n\n' $last_conveyance_offline_ago
      if (( $(($last_short_offline_ago-65535)) > 0 || $(($last_extended_offline_ago-65535)) > 0 || $(($last_conveyance_offline_ago-65535)) > 0 ));then
        echo
        echo "ADJUSTED values calculation:"
        if (( $(($last_short_offline_ago-65535)) > 0 ));then
          printf -- '-----> last_short_offline_ago       = %5i hours ago'   $(($last_short_offline_ago-65535))
          echo -e " (" $(units " $(($last_short_offline_ago-65535))hours" time |sed 's|hr .*|hr|g') ")"
        fi
        if (( $(($last_extended_offline_ago-65535)) > 0 ));then
          printf -- '-----> last_extended_offline_test   = %5i hours ago'   $(($last_extended_offline_ago-65535))
          echo -e " (" $(units "$(($last_extended_offline_ago-65535)) hours" time |sed 's|hr .*|hr|g') ")"
        fi
        if (( $(($last_conveyance_offline_ago-65535)) > 0 ));then
          printf -- '-----> last_conveyance_offline_test = %5i hours ago' $(($last_conveyance_offline_ago-65535))
          echo -e " (" $(units "$(($last_conveyance_offline_ago-65535)) hours" time |sed 's|hr .*|hr|g') ")\n"
        fi
      fi
    else
      printf -- '-----> power_on_hours               = %5i hours, %2.2f years' $power_on_hours $(echo "scale=2; $power_on_hours/24/365.25"|bc)
      echo -e " (" $(units "${power_on_hours} hours" time |sed 's|hr .*|hr|g') ")\n"

      printf -- '-----> last_short_offline_ago       = %5i hours ago'   $last_short_offline_ago
      echo -e " (" $(units "${last_short_offline_ago} hours" time |sed 's|hr .*|hr|g') ")"

      printf -- '-----> last_extended_offline_test   = %5i hours ago'   $last_extended_offline_ago
      echo -e " (" $(units "${last_extended_offline_ago} hours" time |sed 's|hr .*|hr|g') ")"


      printf -- '-----> last_conveyance_offline_test = %5i hours ago' $last_conveyance_offline_ago
      echo -e " (" $(units "${last_conveyance_offline_ago} hours" time |sed 's|hr .*|hr|g') ")\n"
    fi
  fi

  if (( script_is_run_interactively )) && (( $# != 1 )) ;then
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

