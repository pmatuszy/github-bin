# 2021.05.12 - v. 0.3 - added copying .[a-zA-Z0-9]
# 2021.04.08 - v. 0.2 - added HOST-SPECIFIC directory copy
# 2020.11.27 - v. 0.1 - initial release

echo
echo "Do you want to do kind of git pull and configure local scripts? [y/N]"
read -t 5 -n 1 p     # read one character (-n) with timeout of 5 seconds
echo
echo
if [ "${p}" == 'y' -o  "${p}" == 'y' ]; then
  cd $HOME
  mkdir -p $HOME/bin
  rm -rf $HOME/github-bin/*
  rm -rf $HOME/github-bin/.git
  git clone git+ssh://git@github.com/pmatuszy/github-bin.git
  cp -v github-bin/* $HOME/bin
  cp -v github-bin/HOST-SPECIFIC/`hostname`/* $HOME/bin
  cp -v github-bin/HOST-SPECIFIC/`hostname`/.[a-zA-Z0-9]* $HOME/bin
  cd github-bin
  git status
else
  echo "no means no - I am exiting..."
  exit 1
fi
