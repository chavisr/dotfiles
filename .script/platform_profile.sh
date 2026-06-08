#!/bin/bash

profile=$(cat /sys/firmware/acpi/platform_profile)

case "$profile" in
low-power)
  profile_waybar="$profile "
  ;;
balanced)
  profile_waybar="$profile "
  ;;
performance)
  profile_waybar="$profile 󱋙"
  ;;
esac

echo $profile_waybar
