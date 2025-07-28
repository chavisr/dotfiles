#!/bin/bash

battery_level=$(cat /sys/class/power_supply/BAT1/capacity)
battery_status=$(cat /sys/class/power_supply/BAT1/status)

if [ "$battery_level" -le 20 ] && [ "$battery_status" != Charging ]; then
  export DISPLAY=:0
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  dunstify "Low Battery" -u critical
fi
