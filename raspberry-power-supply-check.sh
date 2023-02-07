#!/bin/bash

# 2023.02.07 - v. 0.2 - added check if sysbench is installed
# 20xx.xx.xx - v. 0.1 - initial release (date unknown)

# Before running this script, make sure you have sysbench installed:
#           sudo apt-get install sysbench
#
# This script helps you check if your Raspberry pi is correctly powered.
# You can read more about Raspberry pi powering issues here: https://ownyourbits.com/2019/02/02/whats-wrong-with-the-raspberry-pi/


# If you're pi is correctly powered (stable power supply and quality cable), after running the script, you should get something like:
#
# 45.6'C 1400 / 600 MHz 1.3813V -
# 55.3'C 1400 / 1400 MHz 1.3813V -
# 58.0'C 1400 / 1400 MHz 1.3813V -
# 60.2'C 1400 / 1400 MHz 1.3813V -
# 60.2'C 1400 / 1400 MHz 1.3813V -
# 61.1'C 1400 / 1400 MHz 1.3813V -
# 61.1'C 1400 / 1400 MHz 1.3813V -
# 60.8'C 1400 / 1400 MHz 1.3813V -

# If your power supply can't provide a stable 5V 2.5A or if the cable is not good enough, you should get something like:
#
# 45.6'C 1400 / 600 MHz 1.3813V - Under-voltage,
# 55.3'C 1400 / 1400 MHz 1.3813V - Under-voltage,
# 58.0'C 1400 / 1400 MHz 1.3813V - Under-voltage,
# 60.1'C 1400 / 1400 MHz 1.3813V - Under-voltage,
# 60.1'C 1400 / 1400 MHz 1.2875V - Under-voltage, Under-voltage has occurred,
# 59.6'C 1400 / 1200 MHz 1.2875V - Under-voltage, Under-voltage has occurred,
# 60.1'C 1400 / 1200 MHz 1.3813V - Under-voltage, Under-voltage has occurred,
# 60.1'C 1400 / 1200 MHz 1.2875V - Under-voltage,
# 60.1'C 1400 / 1200 MHz 1.2875V - Under-voltage, Under-voltage has occurred,
# 60.7'C 1400 / 1200 MHz 1.2875V - Under-voltage, Under-voltage has occurred,
# 60.7'C 1400 / 1200 MHz 1.2875V - Under-voltage, Under-voltage has occurred,

function throttleCodeMask {
  perl -e "printf \"%s\", $1 & $2 ? \"$3\" : \"$4\""
}

#######################################################################################

# Make the throttled code readable
#
# See https://github.com/raspberrypi/documentation/blob/JamesH65-patch-vcgencmd-vcdbg-docs/raspbian/applications/vcgencmd.md
#
# bit 0 0x80000: Under-voltage detected
# bit 1 0x40000: Arm frequency capped
# bit 2 0x20000: Currently throttled
#
# bit 16 0x8: Under-voltage has occurred
# bit 17 0x4: Arm frequency capped has occurred
# bit 18 0x2: Throttling has occurred
# bit 19 0x1: Soft temperature limit has occurred
#
function throttledToText {
  throttledCode=$1
  throttleCodeMask $throttledCode 0x80000 "Under-voltage, " ""
  throttleCodeMask $throttledCode 0x40000 "Arm frequency capped, " ""
  throttleCodeMask $throttledCode 0x20000 "Currently throttled, " ""
  throttleCodeMask $throttledCode 0x8 "Under-voltage has occurred, " ""
  throttleCodeMask $throttledCode 0x4 "Arm frequency capped has occurred, " ""
  throttleCodeMask $throttledCode 0x2 "Throttling has occurred, " ""
  throttleCodeMask $throttledCode 0x1 "Soft temperature limit has occurred, " ""
}

. /root/bin/_script_header.sh

# Main script, kill sysbench when interrupted
trap 'kill -HUP 0' EXIT

check_if_installed sysbench

type -fP vcgencmd &>/dev/null

if (( $? != 0 ));then
  echo ;  echo "(PGM) vcgencmd not found - are we run on Raspberry PI hardware????" ; echo 
  exit 1
fi


sysbench --test=cpu --cpu-max-prime=10000000 --num-threads=4 run > /dev/null &
maxfreq=$(( $(awk '{printf ("%0.0f",$1/1000); }' < /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) -15 ))

# Read sys info, print and loop
while true; do
  temp=$(vcgencmd measure_temp | cut -f2 -d=)
  real_clock_speed=$(vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f", $2 / 1000000); }' )
  sys_clock_speed=$(awk '{printf ("%0.0f",$1/1000); }' </sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
  voltage=$(vcgencmd measure_volts | cut -f2 -d= | sed 's/000//')
  throttled_text=$(throttledToText $(vcgencmd get_throttled | cut -f2 -d=))
  echo "$temp $sys_clock_speed / $real_clock_speed MHz $voltage - $throttled_text"
  sleep 5
done

. /root/bin/_script_footer.sh

