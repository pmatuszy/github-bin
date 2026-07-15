#!/bin/bash
 
# 2026.07.15 - v. 0.4 - GIT_REPO_DIRECTORY: ${profile_location_dir:-$HOME}/github/github-bin
# 2026.07.15 - v. 0.3 - profile_location_dir fallback: ${HOME:-/root}
# 2026.07.15 - v. 0.2 - run in GIT_REPO_DIRECTORY: ${profile_location_dir}/github/github-bin
# 2023.01.13 - v. 0.1 - initial release

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

export github_project_name=github-bin
profile_root="${profile_location_dir:-$HOME}"
export GIT_REPO_DIRECTORY="${profile_root}/github/${github_project_name}"

echo
cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

echo
echo "Do you want to do git fetch? [y/N]"
read -t 60 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  if [[ ! -d "${GIT_REPO_DIRECTORY}" ]]; then
    echo  ; echo ; echo "GIT_REPO_DIRECTORY = ${GIT_REPO_DIRECTORY} doesn't exist.... EXITING" ; echo ; echo
    exit 1
  fi
  cd "${GIT_REPO_DIRECTORY}" || exit 2

  # sprawdzam, czy mam dostep do zdalnego repo
  git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo  ; echo ; echo "No access to remote repository.... EXITING" ; echo ; echo
    exit 2
  fi
  git add --all * .[a-zA-Z]*
  git fetch git+ssh://git@github.com/pmatuszy/"${github_project_name}".git
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi
