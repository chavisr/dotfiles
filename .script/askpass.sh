#!/bin/sh
# SUDO_ASKPASS helper: masked password prompt via rofi.
# stdin from /dev/null so rofi shows no list and doesn't consume the caller's input.

exec /usr/bin/rofi -dmenu -password -theme askpass < /dev/null
