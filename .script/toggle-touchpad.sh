#!/bin/bash

CONFIG="$HOME/.config/niri/config.kdl"
FLAG="$HOME/.cache/niri-touchpad-disabled"

if [ -f "$FLAG" ]; then
    # Re-enable: remove the 'off' line we injected
    sed -i '/^    touchpad {/{n; /^        off$/d}' "$CONFIG"
    rm "$FLAG"
    notify-send "Touchpad enabled"
else
    # Disable: inject 'off' as first line inside touchpad block
    sed -i '/^    touchpad {/a\        off' "$CONFIG"
    touch "$FLAG"
    notify-send "Touchpad disabled"
fi
