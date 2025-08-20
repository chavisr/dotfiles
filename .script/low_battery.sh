#!/bin/sh

battery_level=$(cat /sys/class/power_supply/BAT1/capacity)
battery_status=$(cat /sys/class/power_supply/BAT1/status)

if [ "$battery_level" -le 20 ] && [ "$battery_status" != Charging ]; then
  dunstify "Low Battery" -u critical
fi
