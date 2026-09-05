#!/bin/sh

case "$(cat /sys/firmware/acpi/platform_profile)" in
  low-power)   current=0 ;;
  balanced)    current=1 ;;
  performance) current=2 ;;
  *)           current="" ;;
esac

# Put the cursor on the active profile
[ -n "$current" ] && set -- -selected-row "$current"

choice=$(printf "🐢 Power-saver\n🐬 Balanced\n🐇 Performance\n" | rofi -dmenu "$@" | awk '{print $2}')

case "$choice" in
  Power-saver) sudo tlp power-saver ;;
  Balanced) sudo tlp balanced ;;
  Performance) sudo tlp performance ;;
esac

# Send signal to waybar
pkill -SIGRTMIN+8 waybar
