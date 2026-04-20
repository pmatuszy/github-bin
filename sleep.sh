#!/bin/bash

# 2026.04.20 - v. 0.3 - added _script_header.sh and _script_footer.sh integration
# 2026.04.20 - v. 0.2 - style update to match other scripts in this directory
# 2026.04.20 - v. 0.1 - initial release

. /root/bin/_script_header.sh

kod_powrotu=1

if type -fP systemctl 2>&1 >/dev/null; then
  systemctl suspend
  kod_powrotu=$?
elif type -fP pm-suspend 2>&1 >/dev/null; then
  pm-suspend
  kod_powrotu=$?
else
  echo
  echo "(PGM) I can't find systemctl or pm-suspend utility... exiting ..."
  echo
  kod_powrotu=1
fi

. /root/bin/_script_footer.sh

exit ${kod_powrotu}
