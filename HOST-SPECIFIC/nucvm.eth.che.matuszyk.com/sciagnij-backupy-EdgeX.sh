#!/bin/bash

# 2023.03.14 - v. 0.1 - initial release

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR

SKAD=192.168.1.1:/root/config/config.boot_2023.05.*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config

eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files
