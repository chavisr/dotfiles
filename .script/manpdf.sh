#!/bin/sh

man -k . | awk '{print $1}' | uniq | rofi -dmenu | xargs -r man -Tpdf | ifne zathura -
