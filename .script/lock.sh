#!/bin/sh
# /etc/elogind/system-sleep/lock.sh
# Lock before suspend integration with elogind

username=chavi
export XDG_RUNTIME_DIR="/run/user/$(id -u $username)"
export WAYLAND_DISPLAY="wayland-1"
case "${1}" in
  pre)
    su $username -c "/usr/bin/swaylock" &
    sleep 1s
    ;;
esac
