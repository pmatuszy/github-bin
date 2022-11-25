#!/bin/bash
# 2020.11.25 - v. 0.2 - added figlet
# 2020.11.11 - v. 0.1 - initial release

figlet -w 120 kernel logs
sleep 1

dmesg -wT --color=never
