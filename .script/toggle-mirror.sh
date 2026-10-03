#!/bin/bash

if pkill -u "$UID" -x wl-mirror; then
    notify-send "Mirror eDP-1" "Disabled"
    exit 0
fi

wl-mirror --fullscreen-output HDMI-A-1 eDP-1 &
mirror_pid=$!

# Catch immediate failures, such as a missing or disconnected output.
sleep 0.3
if kill -0 "$mirror_pid" 2>/dev/null; then
    notify-send "Mirror eDP-1" "Enabled"
    wait "$mirror_pid"
else
    notify-send -u critical "Mirror eDP-1" "Failed to start"
    wait "$mirror_pid"
    exit 1
fi
