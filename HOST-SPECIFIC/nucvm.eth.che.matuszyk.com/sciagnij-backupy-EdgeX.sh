#!/bin/bash

# 2023.03.14 - v. 0.1 - initial release

#########
# EdgeR #
#########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR

SKAD=192.168.1.1:/root/config/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files

SKAD=192.168.1.1:/root/adresy-ip-historia/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files

SKAD=192.168.1.1:/config/ARCHIWUM_CONFIGOW-EdgeR/config.boot-Edge*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config/ARCHIWUM_CONFIGOW-EdgeR
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files

