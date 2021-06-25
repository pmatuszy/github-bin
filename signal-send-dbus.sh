#!/bin/bash
# 2021.06.25 - v.1.0 - initial script release

# +41......
to_number=$1
message_text="$2"

if [ $# -eq 0 ]
  then
    echo ; echo ; echo "No arguments supplied, exiting..."
    echo "1) to_number"
    echo "2) message_text" ; echo ; echo 
    exit 1
fi

dbus-send --session --type=method_call --print-reply --dest="org.asamk.Signal" /org/asamk/Signal org.asamk.Signal.sendMessage string:"${message_text}" array:string: string:"${to_number}"

echo $?
