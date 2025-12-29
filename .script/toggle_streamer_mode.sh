#!/bin/sh

STATE_FILE="$HOME/.steamer_mode_state"

if [ -f "$STATE_FILE" ]; then
    ln -sf "$HOME/.config/alacritty/default.toml" "$HOME/.config/alacritty/alacritty.toml"
    rm -f "$STATE_FILE"
else
    ln -sf "$HOME/.config/alacritty/streamer.toml" "$HOME/.config/alacritty/alacritty.toml"
    touch "$STATE_FILE"
fi
