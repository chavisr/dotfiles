#!/bin/sh
# SUDO_ASKPASS helper for Claude Code.
# The Bash tool has no TTY, so `sudo -A <cmd>` calls this instead of
# prompting on the terminal. sudo passes its prompt string as $1.
# Prints the password on stdout; exits non-zero if cancelled.

if command -v zenity >/dev/null 2>&1; then
    exec zenity --password --title="${1:-sudo password}" 2>/dev/null
fi

# No graphical helper installed.
notify-send "Claude Code" "sudo needs zenity: install it with 'sudo pacman -S zenity'" 2>/dev/null
echo "claude-askpass: zenity not found; install it with 'sudo pacman -S zenity'" >&2
exit 1
