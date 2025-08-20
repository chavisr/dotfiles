#!/bin/sh

man -k . | awk '{print $1}' | uniq | rofi -dmenu -config "$HOME/.config/rofi/config.noicon.rasi" | xargs -r man -Tpdf | ifne zathura -
