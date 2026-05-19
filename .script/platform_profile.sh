#!/bin/bash

profile=$(cat /sys/firmware/acpi/platform_profile)

case "$profile" in
  low-power)
    profile_icon="🐢"
    ;;
  balanced)
    profile_icon="🐬"
    ;;
  performance)
    profile_icon="🐇"
    ;;
esac

echo $profile_icon
