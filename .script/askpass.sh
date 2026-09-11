#!/bin/sh
# SUDO_ASKPASS helper.
# The Bash tool has no TTY, so `sudo -A <cmd>` calls this instead of
# prompting on the terminal. sudo passes its prompt string as $1.
# Prints the password on stdout; exits non-zero if cancelled.

if command -v rofi >/dev/null 2>&1; then
    exec rofi -dmenu -password -p " " -theme askpass -lines 0 < /dev/null
fi

# No graphical helper installed.
notify-send "Askpass" "sudo needs rofi: install it with 'sudo pacman -S rofi'" 2>/dev/null
echo "askpass: rofi not found; install it with 'sudo pacman -S rofi'" >&2
exit 1
