#!/bin/bash

# 2021.05.20 - v. 0.1 - initial release


if [ ! -f /opt/signal-cli/bin/signal-cli ];then
  echo 
  echo "signal-cli is not installed (/opt/signal-cli/bin/signal-cli)"
  echo 
  exit 1
fi

time /opt/signal-cli/bin/signal-cli send -m "test from `/bin/hostname`" --note-to-self
