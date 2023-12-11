#!/bin/bash

# 2023.12.11 - v. 0.1 - initial release

pkill --full bitcoind

pkill --full litecoincashd

sleep 1 

screen -x
