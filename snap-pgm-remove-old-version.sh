#!/bin/bash

# 2026.04.21 - v. 0.56 - revert v0.55 single-list cache (answered y but no removals); restore per-step snap list like v0.54
# 2026.04.21 - v. 0.54 - accept Y as yes (prompt text stays [y/N/q]); strip CR on answer
# 2026.04.21 - v. 0.53 - prompt adds q/Q to quit without removing; quit runs footer and exits 0
# 2025.10.27 - v. 0.52- bugfix - with ChatGPT fix for kod_powrotu
# 2025.10.27 - v. 0.51- bugfix - small cosmetic display change
# 2023.10.02 - v. 0.5 - bugfix - prompt logic reverse (if there are snaps to be removed no prompt was displayed)
# 2023.09.11 - v. 0.4 - if none of snaps are disabled there is no prompt - the scripts just ends...
# 2023.08.01 - v. 0.3 - added batchmode and prompt
# 2023.07.31 - v. 0.2 - added check for snap command (and if it is not there then install it)
# 2023.07.31 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed snap
check_if_installed boxes

batch_mode=0

if (( $# != 0 )) && [ "${1-nonbatch}" == "batch" ]; then
  echo ; echo "(PGM) enabling batch mode (no questions asked)"
  batch_mode=1
fi

# from https://askubuntu.com/questions/1371833/howto-free-up-space-properly-on-my-var-lib-snapd-filesystem-when-snapd-is-unava

echo "(PGM) All snap releases:" | boxes -a c -d stone
snap list --all

echo
echo "(PGM) Snap released disabled which will be removed:" | boxes -a c -d stone
snap list --all | grep disabled
echo 

snap list --all | strings | grep -q disabled 
kod_powrotu=${PIPESTATUS[2]}   # index 0=snap, 1=strings, 2=grep

if (( $kod_powrotu != 0 )); then
  echo NONE; echo
  . /root/bin/_script_footer.sh
  exit 0
fi

echo "Do you want to do remove disabled packages? [y/N/q]"
if (( $batch_mode == 0 ));then
  read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
else
  echo "y (autoanswer in a batch mode)"
  p=y # batch mode ==> we set the answer to 'y'
fi

echo
p="${p//$'\r'/}"
if [[ "${p}" == [qQ] ]]; then
  echo "(PGM) Quit — no packages removed."
  . /root/bin/_script_footer.sh
  exit 0
fi
if [[ "${p}" != [yY] ]]; then
  echo "no means no - I am exiting..."
  exit 1
fi

LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
while read pkg revision; do
  sudo snap remove "$pkg" --revision="$revision"
done

. /root/bin/_script_footer.sh
