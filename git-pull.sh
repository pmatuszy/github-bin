#!/bin/bash

# 2023.02.18 - v. 1.0 - some minor changes like printing script version in non-interactive mode
# 2023.02.11 - v. 1.0 - added GIT_SSH_COMMAND
# 2023.02.07 - v. 0.9 - added batch mode
# 2023.01.24 - v. 0.8 - added 2>/dev/null to one of the cp commands, size of the boxes width changed from 40 to 70
# 2023.01.13 - v. 0.7 - git clone is replaced with git pull, some small changes 
# 2022.12.13 - v. 0.6 - hostname specified with start (works with or without domainaname)
# 2022.09.30 - v. 0.5 - checking if we have access to remote repo
# 2022.05.18 - v. 0.4 - added removing git-pull.sh and gill-push.sh from $HOME/bin
#                       added set -o options at the beginning
# 2021.05.12 - v. 0.3 - added copying .[a-zA-Z0-9]
# 2021.04.08 - v. 0.2 - added HOST-SPECIFIC directory copy
# 2020.11.27 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if (( ! script_is_run_interactively ));then    # jesli nie interaktywnie, to chcemy wyswietlic info, by poszlo do logow
  echo "${SCRIPT_VERSION}";echo 
fi

export github_project_name=github-bin
export GIT_REPO_DIRECTORY=/root/"${github_project_name}"

export GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_SSH_ed25519_20230207_OpenSSH'

check_if_installed keychain

eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>&1

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

batch_mode=0

if (( $# != 0 )) && [ "${1-nonbatch}" == "batch" ]; then
  echo ; echo "(PGM) enabling batch mode (no questions asked)"
  batch_mode=1
fi

echo
echo "Do you want to do kind of git pull and configure local scripts? [y/N]"

if (( $batch_mode == 0 ));then
  read -t 300 -n 1 p     # read one character (-n) with timeout of 300 seconds
else
  echo "y (autoanswer in a batch mode)"
  p=y # batch mode ==> we set the answer to 'y'
fi
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  cd $HOME
  mkdir -p $HOME/bin

  # sprawdzam, czy mam dostep do zdalnego repo
  echo git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git | boxes -s 70x3 -a c
  git ls-remote git+ssh://git@github.com/pmatuszy/"${github_project_name}".git 2>&1 >/dev/null
  if (( $? != 0 )); then
    echo  ; echo ; echo "Nie mam dostepu do zdalnego repozytorium.... WYCHODZE" ; echo ; echo
    exit 2
  fi

  cd "${GIT_REPO_DIRECTORY}"

  echo git pull git+ssh://git@github.com/pmatuszy/"${github_project_name}".git | boxes -s 70x3 -a c

  git pull git+ssh://git@github.com/pmatuszy/"${github_project_name}".git
  if (( $? != 0 )); then
    echo  ; echo ; echo "Pull was not successful... WYCHODZE" ; echo ; echo
    exit 3
  fi

  cp ./* $HOME/bin 2>/dev/null
  cp ./HOST-SPECIFIC/`hostname`/* $HOME/bin 2>/dev/null
  cp ./HOST-SPECIFIC/`hostname`.*com/* $HOME/bin 2>/dev/null

  # we copy hidden files to $HOME
  cp ./HOST-SPECIFIC/`hostname`*/.[a-zA-Z0-9]* $HOME   2>/dev/null

  # cleanup
  rm -v $HOME/bin/git-pull.sh $HOME/bin/git-push.sh $HOME/bin/git-fetch.sh $HOME/bin/vmware-fix.sh $HOME/bin/65535
  echo 
  echo git status | boxes -s 40x3 -a c
  echo 
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi

. /root/bin/_script_footer.sh

