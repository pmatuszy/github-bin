#!/bin/bash
 
# 2023.01.13 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

echo
cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

echo
echo "Do you want to do git fetch? [y/N]"
read -t 60 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  # sprawdzam, czy mam dostep do zdalnego repo
  git ls-remote git+ssh://git@github.com/pmatuszy/github-bin.git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo  ; echo ; echo "Nie mam dostepu do zdalnego repozytorium.... WYCHODZE" ; echo ; echo
    exit 2
  fi
  git add --all * .[a-zA-Z]*
  git fetch git+ssh://git@github.com/pmatuszy/github-bin.git
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi
