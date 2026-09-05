#!/bin/sh

# Pick a man page (name + section) with rofi, render it to PDF, view it.

sel=$(
	man -k . 2>/dev/null |
		awk -F' *\\(' '{ sec = $2; sub(/\).*/, "", sec); print $1 "(" sec ")" }' |
		sort -u |
		rofi -dmenu -i -p man
) || exit 0

[ -n "$sel" ] || exit 0

name=${sel%%(*}
sec=${sel#*(}
sec=${sec%)}

man -Tpdf "$sec" "$name" | ifne zathura -
