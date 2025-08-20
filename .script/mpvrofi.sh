#!/bin/sh

FOUND_VIDEOS='/tmp/videos'
SEARCH_DIR="${HOME}/incoming"

find "$SEARCH_DIR" -type f \( \
  -iname "*.mp4" \
  -o -iname "*.mkv" \
  -o -iname "*.avi" \
  -o -iname "*.mov" \
  -o -iname "*.flv" \
  -o -iname "*.webm" \
\) > $FOUND_VIDEOS

cat $FOUND_VIDEOS | xargs -I {} basename {} | rofi -i -dmenu -matching fuzzy -config "$HOME/.config/rofi/config.noicon.rasi" | xargs -I {} grep {} $FOUND_VIDEOS | xargs -I {} mpv "{}"
