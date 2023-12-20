#!/bin/bash

# 2023.03.14 - v. 0.1 - initial release

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-www02
SKAD=www02.eth.r.matuszyk.com:/var/www/202*bz2
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/www02

eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD


export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-cloud
SKAD=cloud.eth.r.matuszyk.com:/var/www/202*bz2
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/cloud-var-www

eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD


export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-lublin-healthchecks
SKAD=lublin.eth.r.matuszyk.com:/mnt/luks-RaidSonicB/postgres/backup/lublin.eth.r.matuszyk.com/pgbackrest/backup/healthchecks/*
DOKAD=/mnt/luks-buffalo2/_backupy-1dyne_kopie/postgresql-lublin

eval /root/bin/sciagnij-backupy.sh $SKAD $DOKAD

