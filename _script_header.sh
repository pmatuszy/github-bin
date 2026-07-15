#!/bin/bash

# 2026.07.15 - v. 1.57.210401 - export profile_location_dir (default: $HOME or /root)
# 2026.07.05 - v. 1.57.210400 - fix caller script detection (BASH_SOURCE[1] was _script_header.sh inside function)
# 2026.06.27 - v. 1.56 - prompts: timestamp only; script version stays in window title (not script_version_in_prompt)
# 2026.06.18 - v. 1.55 - PuTTY/window title: script version at front of title bar
# 2026.06.18 - v. 1.54 - resolve caller script via BASH_SOURCE; export SCRIPT_VERSION_NUMBER; PuTTY title + prompt helper
# 2026.06.02 - v. 1.53 - accept --no_startup_delay as alias for NO_STARTUP_DELAY (skip random delay when sourced with that flag)
# 2026.04.21 - v. 1.52 - ctrl_c STY guard; quote $0 in version/tty; year-agnostic changelog grep; -n STY; indent; contract blurb
# 2025.10.28 - v. 1.51- now we set LC_ALL for scripts to have proper separators in numbers (like ,.)
# 2023.10.10 - v. 1.5 - bugfix: removed hardcoded HEALTHCHECKS_FILE
# 2023.05.22 - v. 1.4 - added printing of the script name, added NO_STARTUP_DELAY startup parameter
# 2023.04.11 - v. 1.3 - added printing of the script name
# 2023.02.17 - v. 1.2 - added SCRIPT_VERSION env variable
# 2023.02.10 - v. 1.1 - changed check_if_installed with the option to provide the package name to be installed
# 2023.02.07 - v. 1.0 - added check_if_installed function and checks for figlet and boxes utils
# 2023.01.25 - v. 0.9 - added script_is_run_interactively env variable
# 2023.01.24 - v. 0.8 - added return_code environment variable
# 2023.01.15 - v. 0.7 - change $0 to basename $0 to have a shorter line
# 2022.10.27 - v. 0.6 - but fix for "tcScrTitleEnd" variable
# 2022.05.16 - v. 0.5 - small bug fix with STY unbound variable
# 2022.05.11 - v. 0.4 - set set -o options
# 2021.07.05 - v. 0.3 - added figlet displaying the current script name
# 2020.09.15 - v. 0.2 - initial release
# 2020.09.15 - v. 0.1 - initial release

# Contract: sourced (not executed) by sibling scripts. Enables nounset and pipefail,
# sets LC_ALL=C, defines check_if_installed and ctrl_c, installs boxes/figlet when root,
# sets GNU Screen window title when STY is set, optional RANDOM_DELAY when not on a tty.

if [[ "$0" = "/bin/bash" ]] || [[ "$0" = "/usr/bin/bash" ]] || [[ "$0" = "/usr/local/bin/bash" ]] ; then
  echo do not run the script standalone - only from the script ...
  return 1
fi

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

# set this to get proper numbers with separators - especially for smart*sh scripts which do calculations
export LC_ALL=C

_script_header_resolve_caller_script() {
  local p="" dir base found i

  # When this runs inside a function, BASH_SOURCE[1] is _script_header.sh (the call site),
  # not the script that sourced us — walk the stack and skip header frames.
  for (( i=1; i < ${#BASH_SOURCE[@]}; i++ )); do
    p="${BASH_SOURCE[i]}"
    [[ "$(basename "$p")" == "_script_header.sh" ]] && continue
    if [[ "$p" == */* && -r "$p" ]]; then
      dir="$(cd "$(dirname "$p")" && pwd -P)"
      base="$(basename "$p")"
      printf '%s/%s' "$dir" "$base"
      return 0
    fi
    if [[ -r "./$p" ]]; then
      dir="$(cd "$(dirname "./$p")" && pwd -P)"
      base="$(basename "$p")"
      printf '%s/%s' "$dir" "$base"
      return 0
    fi
    found="$(type -P "$p" 2>/dev/null || true)"
    if [[ -n "$found" && -r "$found" ]]; then
      printf '%s' "$found"
      return 0
    fi
  done

  p="${0:-}"
  if [[ "$p" == */* && -r "$p" ]]; then
    dir="$(cd "$(dirname "$p")" && pwd -P)"
    base="$(basename "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  if [[ -r "./$p" ]]; then
    dir="$(cd "$(dirname "./$p")" && pwd -P)"
    base="$(basename "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  found="$(type -P "$p" 2>/dev/null || true)"
  if [[ -n "$found" && -r "$found" ]]; then
    printf '%s' "$found"
    return 0
  fi
  printf '%s' "$p"
}

CALLER_SCRIPT="$(_script_header_resolve_caller_script)"
export CALLER_SCRIPT
CALLER_SCRIPT_BASENAME="$(basename "$CALLER_SCRIPT")"
export CALLER_SCRIPT_BASENAME

SCRIPT_VERSION_NUMBER="$(
  LC_ALL=C grep -m1 '^# [0-9]' "$CALLER_SCRIPT" 2>/dev/null \
    | sed -E -n 's/^# [0-9]{4}\.[0-9]{2}\.[0-9]{2} - v\. ([0-9]+(\.[0-9]+)*) - .*/\1/p'
)"
SCRIPT_VERSION_DATE="$(
  LC_ALL=C grep -m1 '^# [0-9]' "$CALLER_SCRIPT" 2>/dev/null \
    | sed -E -n 's/^# ([0-9]{4}\.[0-9]{2}\.[0-9]{2}) - v\. .*/\1/p'
)"
[[ -n "$SCRIPT_VERSION_NUMBER" ]] || SCRIPT_VERSION_NUMBER=unknown
export SCRIPT_VERSION_NUMBER SCRIPT_VERSION_DATE

# Optional suffix for prompt timestamps; version belongs in the window title only.
script_version_in_prompt() {
  :
}

script_version_title_prefix() {
  if [[ -n "${SCRIPT_VERSION_NUMBER:-}" && "${SCRIPT_VERSION_NUMBER}" != unknown ]]; then
    printf 'v%s ' "$SCRIPT_VERSION_NUMBER"
  fi
}

#######################################################################################
function ctrl_c() {
  echo
  echo "** Trapped CTRL-C - cleaning up...."
  echo
  if [ -n "${STY:-}" ]; then    # checking if we are running within screen
    # I am setting the screen window title to the script name
    echo -ne "${tcScrTitleStart}${CALLER_SCRIPT_BASENAME}${tcScrTitleEnd}"
  fi
  exit
}
#######################################################################################
function check_if_installed() {

  if [ "$(id -u)" -ne 0 ]; then
    # script is not run as root so we don't want to progress with the installation
    return 1
  fi

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

# if we are run non-interactively - do not set the terminal title
export tcScrTitleStart="\ek"
export tcScrTitleEnd="\033\\"

check_if_installed boxes
check_if_installed figlet

tty 2>&1 >/dev/null
if (( $? == 0 )); then
  echo -ne "\033]0;$(script_version_title_prefix)${CALLER_SCRIPT_BASENAME}\007"
  figlet -w 280 "${CALLER_SCRIPT_BASENAME}"
fi

if [ -n "${STY:-}" ]; then    # checking if we are running within screen
  # I am setting the screen window title to the script name
  echo -ne "${tcScrTitleStart}$(script_version_title_prefix)${CALLER_SCRIPT_BASENAME}${tcScrTitleEnd}"
fi

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

: "${profile_location_dir:=${HOME:-/root}}"
export profile_location_dir

export HEALTHCHECKS_FILE=/root/bin/healthchecks-ids.txt
export return_code=123      # default placeholder; scripts set real exit code
export RANDOM_DELAY=0
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}

export script_is_run_interactively=0

export SCRIPT_VERSION_TMP=$(
  echo "script name: ${CALLER_SCRIPT}" ;
  if [[ "${SCRIPT_VERSION_NUMBER}" != unknown ]]; then
    echo "script version: ${SCRIPT_VERSION_NUMBER} (dated ${SCRIPT_VERSION_DATE})" ;
  else
    echo "script version: unknown" ;
  fi
  echo "current date : $(date '+%Y.%m.%d %H:%M:%S')"
  echo "script is run on $(hostname)" ; echo ; echo
)

export SCRIPT_VERSION=$(echo "${SCRIPT_VERSION_TMP}"  | boxes -s 50x3 -a c -d ada-box )


FORCE_NO_STARTUP_DELAY_var=0

if [ $# -ne 0 ];then      # if there is an argument supplied we gonna check what is that
  case $1 in
    NO_STARTUP_DELAY|--no_startup_delay)
         FORCE_NO_STARTUP_DELAY_var=1
       ;;
    *)
       ;;
  esac
fi

tty 2>&1 >/dev/null
if (( $? != 0 )) ; then      # we set RANDOM_DELAY only when running NOT from terminal
  script_is_run_interactively=0
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  if (( $FORCE_NO_STARTUP_DELAY_var != 1 )); then # we do the delay only when is it NOT requested by command line parameter...
    sleep $RANDOM_DELAY
  fi
else
  echo "Interactive session detected: I will NOT introduce RANDOM_DELAY...";echo
  script_is_run_interactively=1
  echo "${SCRIPT_VERSION}" ; echo
fi
