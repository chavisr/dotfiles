#!/bin/sh

xsetroot -cursor_name left_ptr
xset -dpms
xset s off
xset r rate 300 50
xrandr --output $(xrandr | awk '/ connected/ {print $1; exit}') --mode 1920x1080 --rate 144
xrdb -merge ~/.Xresources
exec bspwm
