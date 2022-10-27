#!/bin/bash
# 2022.10.27 - v. 0.3 - printing correct values when power on hours > 65535
# 2022.10.12 - v. 0.2 - small fix to power_on_hours display 
# 2022.10.11 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail
# if we are run non-interactively - do not set the terminal title
export tcScrTitleStart="\ek"
export tcScrTitleEnd="\e\134"

if [ ! -z ${STY:-} ]; then    # checking if we are running within screen
  # I am setting the screen window title to the script name
  echo -ne "${tcScrTitleStart}${0}${tcScrTitleEnd}"
fi

echo ; cat  $0|grep -e '2022'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, exiting..."
    echo "$0 disk_name" ; echo ; echo 
    exit 1
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="-l selftest"

export SMARTCTL_BIN=$(type -fP smartctl)

$SMARTCTL_BIN  --info $1 2>&1 > /dev/null

if (( $? == 1 ));then 
  DEVICE_TYPE='-d sat'
fi

$SMARTCTL_BIN $DEVICE_TYPE --info $1 2>&1 > /dev/null
if (( $? == 1 ));then 
  echo  ; echo "I don't know which device type (-d), so I am quitting" ; echo ; echo exit 1
  exit 1
fi

$SMARTCTL_BIN $DEVICE_TYPE --info $1 2>&1 > /dev/null
if (( $? == 2 ));then
  echo  ; echo "No such a device, I am exiting " ; echo ; echo exit 2 ; echo 
  exit 2
fi

czy_seagate=$($SMARTCTL_BIN  $DEVICE_TYPE --info $1|grep -i seagate | wc -l)
if (( $czy_seagate > 0 ));then
  VENDOR_ATTRIBUTE="-v 1,raw48:54 -v 7,raw48:54 -v 187,raw48:54  -v 188,raw48:54 -v 195,raw48:54"
fi

export power_on_hours=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE -A $1 | egrep '^  9' | awk '{print $10}'|sed 's|[hms].*||g')     # ost sed zostawia tylko 24979 z "24979h+00m+00.000s"
export last_short_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $1 | grep -i 'Short offline'|head -1|sed 's|.*% *||g' | awk '{print $1}')
export last_extended_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $1 | grep -i 'Extended offline'|head -1|sed 's|.*% *||g' | awk '{print $1}')
export last_conveyance_offline_test=$($SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $1 | grep -i 'Conveyance offline'|head -1|sed 's|.*% *||g' | awk '{print $1}')

let last_short_offline_ago=power_on_hours-last_short_offline_test
let last_extended_offline_ago=power_on_hours-last_extended_offline_test
let last_conveyance_offline_ago=power_on_hours-last_conveyance_offline_test
echo

$SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $1 |sed 's|\(.*failure.*\)|\1                             < ----- ! ! ! ! ! ! ! FAILURE ! ! ! ! ! ! !|g'

echo

if (( $power_on_hours > 65535 ));then
  printf -- '-----> power_on_hours               = %5i (possible wrap around as it is more than 65535 hours.... )\n\n' $power_on_hours
  echo "RAW values calculation:"
  printf -- '-----> last_short_offline_ago       = %5i\n'   $last_short_offline_ago
  printf -- '-----> last_extended_offline_test   = %5i\n'   $last_extended_offline_ago
  printf -- '-----> last_conveyance_offline_test = %5i\n\n' $last_conveyance_offline_ago
  echo
  echo "ADJUSTED values calculation:"
  printf -- '-----> last_short_offline_ago       = %5i\n'   $(($last_short_offline_ago-65535))
  printf -- '-----> last_extended_offline_test   = %5i\n'   $(($last_extended_offline_ago-65535))
  printf -- '-----> last_conveyance_offline_test = %5i\n\n' $(($last_conveyance_offline_ago-65535))
else
  printf -- '-----> power_on_hours               = %5i\n\n' $power_on_hours
  printf -- '-----> last_short_offline_ago       = %5i\n'   $last_short_offline_ago
  printf -- '-----> last_extended_offline_test   = %5i\n'   $last_extended_offline_ago
  printf -- '-----> last_conveyance_offline_test = %5i\n\n' $last_conveyance_offline_ago
fi

