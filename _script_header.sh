#!/bin/bash

# 2023.02.07 - v. 1.0 - added check_if_installed function and checks for figlet and boxes utils
# 2023.01.25 - v. 0.9 - added script_is_run_interactively env variable
# 2023.01.24 - v. 0.8 - added kod_powrotu environment variable
# 2023.01.15 - v. 0.7 - change $0 to basename $0 to have a shorter line
# 2022.10.27 - v. 0.6 - but fix for "tcScrTitleEnd" variable
# 2022.05.16 - v. 0.5 - small bug fix with STY unbound variable
# 2022.05.11 - v. 0.4 - set set -o options
# 2021.07.05 - v. 0.3 - added figlet displaying the current script name
# 2020.09.15 - v. 0.2 - initial release
# 2020.09.15 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

# if we are run non-interactively - do not set the terminal title
export tcScrTitleStart="\ek"
export tcScrTitleEnd="\033\\"

tty 2>&1 >/dev/null
if (( $? == 0 )); then
  echo -ne "\033]0;`hostname` - $0\007";\
  figlet -w 280 `basename $0`
fi

if [ ! -z ${STY:-} ]; then    # checking if we are running within screen
  # I am setting the screen window title to the script name
  echo -ne "${tcScrTitleStart}${0}${tcScrTitleEnd}"
fi

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

##############################################################################################################################################################################
function ctrl_c() {
 echo
 echo "** Trapped CTRL-C - cleaning up...."
 echo
 if [ ! -zwhy ${STY:-} ]; then    # checking if we are running within screen
    # I am setting the screen window title to the script name
    echo -ne "${tcScrTitleStart}${0}${tcScrTitleEnd}"
 fi
 exit
}
#######################################################################################
function check_if_installed() {
type -fP "${1}" &>/dev/null

if (( $? != 0 ));then
  echo ; echo "#######################################################"
  echo "(PGM) ${1} not found - I will install it..."
  if [ "${2:-BRAK}" != "BRAK" ];then
    apt-get -y install "${2}"
  else
    apt-get -y install "${1}"
  fi
  echo "#######################################################";echo
fi
type -fP "${1}" 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find ${1} utility... exiting ..."; echo
  exit 1
fi
}
#######################################################################################

export HEALTHCHECKS_FILE=/root/bin/healthchecks-ids.txt
export kod_powrotu=123      # bezsensowny jakis, ale wazne, by zmienna byla zdefiniowana
export RANDOM_DELAY=0
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}

export script_is_run_interactively=0

tty 2>&1 >/dev/null
if (( $? != 0 )); then      # we set RANDOM_DELAY only when running NOT from terminal
  script_is_run_interactively=0
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  sleep $RANDOM_DELAY
else
  echo ; echo "Interactive session detected: I will NOT introduce RANDOM_DELAY..."
  script_is_run_interactively=1
  echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
  echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo 
fi

check_if_installed boxes
check_if_installed figlet


