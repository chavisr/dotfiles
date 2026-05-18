#!/bin/sh

choice=$(printf "🐢 Power-saver\n🐬 Balanced\n🐇 Performance\n" | rofi -dmenu | awk '{print $2}')

case "$choice" in
  Power-saver) sudo tlp power-saver ;;
  Balanced) sudo tlp balanced ;;
  Performance) sudo tlp performance ;;
esac

# To verify
# cat /sys/firmware/acpi/platform_profile
