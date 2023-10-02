#!/bin/bash

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

snap list --all |grep -q disabled 

if (( $? == 0 )); then
  echo NONE; echo
  exit 0
fi

echo "Do you want to do remove disabled packages? [y/N]"
if (( $batch_mode == 0 ));then
  read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
else
  echo "y (autoanswer in a batch mode)"
  p=y # batch mode ==> we set the answer to 'y'
fi

echo
if [ "${p}" != 'y' -a  "${p}" != 'y' ]; then
  echo "no means no - I am exiting..."
  exit 1
fi

LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
while read pkg revision; do
  sudo snap remove "$pkg" --revision="$revision"
done

. /root/bin/_script_footer.sh
