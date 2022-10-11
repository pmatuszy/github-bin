#!/bin/bash

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

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, exiting..."
    echo "$0 disk_name" ; echo ; echo 
    exit 1
fi

DEVICE_TYPE=""
VENDOR_ATTRIBUTE=""
SUBCOMMAND="-A "
export SMARTCTL_BIN=$(type -fP smartctl)

$SMARTCTL_BIN  --info $1 2>&1 > /dev/null

if (( $? == 1 ));then 
  DEVICE_TYPE='-d sat'
fi

$SMARTCTL_BIN $DEVICE_TYPE --info $1 2>&1 > /dev/null
if (( $? == 1 ));then 
  echo  ; echo "I don't know which device type (-d), so I am quitting" ; echo ; echo exit 1 ; echo 
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
$SMARTCTL_BIN $DEVICE_TYPE $VENDOR_ATTRIBUTE $SUBCOMMAND $1
