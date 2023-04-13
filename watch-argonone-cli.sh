#!/bin/bash

# 2023.04.13 - v. 0.2 - added check if argonone-cli is installed
# 2021.09.19 - v. 0.1 - inicjalna wersja skryptu

type -fP argonone-cli 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find argonone-cli utility... exiting ..."; echo
  exit 1
fi

watch -n 0.2 argonone-cli --decode
