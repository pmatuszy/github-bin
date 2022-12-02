#!/bin/bash
# 2022.12.02 - v. 0.2 - better detection of journalctl binary location with type
# 2022.11.25 - v. 0.1 - initial release

echo ; cat  $0|grep -e '2022'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

figlet -w 120 logs from systemd
sleep 1.5s

export JOURNALCTL_BIN=$(type -fP journalctl )

${JOURNALCTL_BIN} -fan500

#  -f --follow                Follow the journal
#  -a --all                   Show all fields, including long and unprintable
#  -n --lines[=INTEGER]       Number of journal entries to show

