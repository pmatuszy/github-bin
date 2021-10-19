#!/bin/bash

# 2021.10.19 - v. 0.1 - initial release

api_key='83BJNTPZVXHFUIQ0'

fan_speed=`argonone-cli --decode|grep 'Fan Status ON Speed'|sed 's/Fan Status ON Speed //'|tr -d "%"`
CPUtemp=`argonone-cli --decode|grep "System Temperature "|sed 's/System Temperature //'|tr -dc '0-9'`

# echo "fan_speed = $fan_speed CPUtemp = $CPUtemp"

curl --data "api_key=$api_key&field1=$fan_speed&field2=$CPUtemp" https://api.thingspeak.com/update
