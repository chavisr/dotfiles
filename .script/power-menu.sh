#!/bin/sh

choice=$(
  printf '%s\n' \
    '  Lock' \
    '  Sleep' \
    '  Reboot' \
    '  Poweroff' |
    rofi -dmenu -format i -no-custom
) || exit 0

case "$choice" in
  0) swaylock ;;
  1) loginctl suspend ;;
  2) loginctl reboot ;;
  3) loginctl poweroff ;;
esac
