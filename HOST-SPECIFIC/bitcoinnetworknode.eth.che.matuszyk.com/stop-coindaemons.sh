#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2023.12.11 - v. 0.1 - initial release

pkill --full bitcoind
pkill --full litecoincashd

sleep 1 

screen -x
