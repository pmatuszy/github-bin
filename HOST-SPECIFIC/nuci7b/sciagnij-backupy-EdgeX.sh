#!/bin/bash

# 2023.07.17 - v. 0.2 - added output redirection to /dev/null
# 2023.03.14 - v. 0.1 - initial release

##########
# EdgeSS #
##########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat1
SKAD=192.168.17.1:/root/config/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/EdgeSS-root_config
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat2
SKAD=192.168.17.1:/root/adresy-ip-historia/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/EdgeSS-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat3
SKAD=192.168.17.1:/config/ARCHIWUM_CONFIGOW-EdgeSS/
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/EdgeSS-root_config/ARCHIWUM_CONFIGOW-EdgeSS
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

###########
# EdgeCHE #
###########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat1
SKAD=192.168.200.1:/root/config/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/EdgeCHE-root_config
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat2
SKAD=192.168.200.1:/root/adresy-ip-historia/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/EdgeCHE-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat3
SKAD=192.168.200.1:/config/ARCHIWUM_CONFIGOW-EdgeCHE/
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/EdgeCHE-root_config/ARCHIWUM_CONFIGOW-EdgeCHE
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

#########
# EdgeR #
#########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat1
SKAD=192.168.1.1:/root/config/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat2
SKAD=192.168.1.1:/root/adresy-ip-historia/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat3
SKAD=192.168.1.1:/config/ARCHIWUM_CONFIGOW-EdgeR/
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config/ARCHIWUM_CONFIGOW-EdgeR
eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD --remove-source-files >/dev/null 2>&1
