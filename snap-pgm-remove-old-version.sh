#!/bin/bash

# 2026.04.21 - v. 0.55 - removal loop: set +e so first snap failure does not exit script; here-string loop; log each remove
# 2026.04.21 - v. 0.54 - normalize read answer (strip CR/LF); read -r; case-insensitive y
# 2026.04.21 - v. 0.53 - fix confirm test (was != y twice; accept y or Y)
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

echo "Do you want to do remove disabled packages? [y/N]"
if (( $batch_mode == 0 ));then
  # -r: no backslash escapes; strip CR (Windows/Git Bash) so "y" matches
  read -r -t 300 -n 1 p
else
  echo "y (autoanswer in a batch mode)"
  p=y
fi

echo
p="${p//$'\r'/}"
p="${p//$'\n'/}"
p="${p:0:1}"
if [[ "${p,,}" != "y" ]]; then
  echo "no means no - I am exiting..."
  exit 1
fi

# With set -e (often from _script_header.sh), a failing `snap remove` in a piped while
# subshell exits the whole script before _script_footer — looks like "y then nothing".
_snap_rm_plan=$(LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}')
if [[ -z "${_snap_rm_plan//[$' \t\r\n']/}" ]]; then
  echo "(PGM) awk produced no pkg/revision pairs; nothing to remove."
else
  _errexit_was_on=0
  [[ $- == *e* ]] && _errexit_was_on=1
  set +e
  remove_failures=0
  while IFS= read -r pkg revision; do
    [[ -n "$pkg" && -n "$revision" ]] || continue
    echo "(PGM) Removing ${pkg} @ revision ${revision} ..."
    if ! sudo snap remove "${pkg}" --revision="${revision}"; then
      echo "(PGM) snap remove failed for ${pkg} revision ${revision} (see above)." >&2
      ((++remove_failures)) || true
    fi
  done <<< "${_snap_rm_plan}"
  ((_errexit_was_on)) && set -e
  if (( remove_failures > 0 )); then
    echo "(PGM) Finished with ${remove_failures} removal error(s)." >&2
  else
    echo "(PGM) All scheduled removals completed successfully."
  fi
fi

. /root/bin/_script_footer.sh
