#!/bin/sh

choice=$(printf "🔐 Lock\n💤 Sleep\n♻️ Reboot\n⭕ Poweroff\n" | rofi -dmenu | awk '{print $2}')

case "$choice" in
  Lock) swaylock ;;
  Sleep) loginctl suspend ;;
  Reboot) loginctl reboot ;;
  Poweroff) loginctl poweroff ;;
esac
