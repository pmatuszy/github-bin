#!/bin/bash

# 2022.12.02 - v. 0.1 - inicjalna wersja skryptu

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

echo "Your system is $(getconf LONG_BIT)-bit" ; echo

