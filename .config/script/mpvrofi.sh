#!/bin/sh

find "${HOME}/incoming" -type f \( -iname "*.mp4" -o -iname "*.mkv" \) > /tmp/rofi_videos

cat /tmp/rofi_videos | xargs -I {} basename {} | rofi -i -dmenu -matching fuzzy -config "$HOME/.config/rofi/config.noicon.rasi" | xargs -I {} grep {} /tmp/rofi_videos | xargs -I {} mpv "{}"
