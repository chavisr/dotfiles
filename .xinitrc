#!/bin/sh

xsetroot -cursor_name left_ptr
xset -dpms
xset s off
xset r rate 300 50
xrandr --output DP-2 --mode 1920x1080 --rate 144
exec bspwm > /dev/null
