#!/bin/sh

# Pick a man page (name + section) with rofi, render it to PDF, view it.

page=$(
	man -k . 2>/dev/null |
		sed 's/ *(/(/; s/).*/)/' |
		sort -u |
		rofi -dmenu -i -p man
) || exit 0

[ -n "$page" ] || exit 0

[ -n "$BROWSER" ] || {
	printf '%s\n' 'manpdf: BROWSER is not set' >&2
	exit 1
}

pdf=$(mktemp "${TMPDIR:-/tmp}/manpdf.XXXXXX.pdf") || exit 1

if ! man -Tpdf -- "$page" > "$pdf" || [ ! -s "$pdf" ]; then
	rm -f -- "$pdf"
	exit 1
fi

exec "$BROWSER" "$pdf"
