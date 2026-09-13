#!/bin/sh

choice=$(printf '%s\n' '🔐 Lock' '💤 Sleep' '♻️ Reboot' '⭕ Poweroff' | rofi -dmenu)

case "$choice" in
  '🔐 Lock') swaylock ;;
  '💤 Sleep') loginctl suspend ;;
  '♻️ Reboot') loginctl reboot ;;
  '⭕ Poweroff') loginctl poweroff ;;
esac
