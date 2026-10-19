#!/bin/sh

case "$(cat /sys/firmware/acpi/platform_profile)" in
  low-power)   current=0 ;;
  balanced)    current=1 ;;
  performance) current=2 ;;
  *)           current="" ;;
esac

# Put the cursor on the active profile.
[ -n "$current" ] && set -- --select-index "$current"

choice=$(printf "  Low-power\n  Balanced\n󱋙  Performance\n" | fuzzel --dmenu --index --no-sort "$@") || exit 0

case "$choice" in
  0) sudo -A tlp power-saver ;;
  1) sudo -A tlp balanced ;;
  2) sudo -A tlp performance ;;
  *) exit 0 ;;
esac

# Send signal to waybar
pkill -SIGRTMIN+8 waybar
