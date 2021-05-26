#!/bin/bash
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR
# 2021.05.20 - v. 0.1 - initial release


if [ ! -f /opt/signal-cli/bin/signal-cli ];then
  echo 
  echo "signal-cli is not installed (/opt/signal-cli/bin/signal-cli)"
  echo 
  exit 1
fi

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

time /opt/signal-cli/bin/signal-cli send -m "[`date '+%Y.%m.%d %H:%M:%S'`] test from `hostname`" --note-to-self
