#!/bin/sh

USER_NAME=chavi
USER_UID=$(id -u "$USER_NAME")
RUNTIME_DIR="/run/user/$USER_UID"

export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export NIRI_SOCKET="$(find "$RUNTIME_DIR" -maxdepth 1 -name 'niri.wayland-*.sock' -print -quit)"

if [ "$(cat /sys/class/drm/card1-HDMI-A-1/status)" = "connected" ]; then
  runuser -u "$USER_NAME" -- niri msg output HDMI-A-1 on
  runuser -u "$USER_NAME" -- niri msg output eDP-1 off
else
  runuser -u "$USER_NAME" -- niri msg output HDMI-A-1 off
  runuser -u "$USER_NAME" -- niri msg output eDP-1 on
fi
