#!/bin/bash

WALLPAPER_DIR="$HOME/.config/wallpaper"
INDEX_FILE="$HOME/.current_wallpaper_index"

# Get all wallpapers in an array
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f | sort)
TOTAL=${#WALLPAPERS[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Read current index or start at 0 if none
if [[ -f $INDEX_FILE ]]; then
  CURRENT_INDEX=$(cat "$INDEX_FILE")
else
  CURRENT_INDEX=0
fi

case "$1" in
  next)
    NEW_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL ))
    ;;
  prev)
    NEW_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL) % TOTAL ))
    ;;
  *)
    echo "Usage: $0 {next|prev}"
    exit 1
    ;;
esac

# Set wallpaper
feh --no-fehbg --bg-fill "${WALLPAPERS[$NEW_INDEX]}"

# Save new index
echo $NEW_INDEX > "$INDEX_FILE"
