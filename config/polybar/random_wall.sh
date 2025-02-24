#!/bin/sh

WALLPAPER_DIR="$HOME/.config/wallpaper"

RANDOM_PIC=$(ls $WALLPAPER_DIR | shuf -n 1)

feh --no-fehbg --bg-fill $WALLPAPER_DIR/$RANDOM_PIC
