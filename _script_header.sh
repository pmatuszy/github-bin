# 2021.07.05 - v. 0.3 - added figlet displaying the current script name
# 2020.09.15 - v. 0.2 - initial release
# 2020.09.15 - v. 0.1 - initial release

# if we are run non-interactively - do not set the terminal title

export tcScrTitleStart="\ek"
export tcScrTitleEnd="\e\134"

tty 2>&1 >/dev/null
if (( $? == 0 )); then
  echo -ne "\033]0;`hostname` - $0\007";\
  figlet -w 280 $0
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
 if [ ! -zwhy $STY ]; then    # checking if we are running within screen
    # I am setting the screen window title to the script name
    echo -ne "${tcScrTitleStart}${0}${tcScrTitleEnd}"
 fi
 exit
}

export HEALTHCHECKS_FILE=/root/bin/healthchecks-ids.txt
