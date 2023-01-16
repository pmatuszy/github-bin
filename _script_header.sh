#!/bin/bash

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

export HEALTHCHECKS_FILE=/root/bin/healthchecks-ids.txt
