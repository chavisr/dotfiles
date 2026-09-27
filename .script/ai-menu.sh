#!/bin/sh

config="$HOME/.config/niri/config.kdl"

choice=$(
  printf '%s\n' \
    "🍒 Codex" \
    "🍊 Claude" \
    "🫐 OpenCode" |
    rofi -dmenu -format i
)

# Match the zero-based menu position, so labels can contain any text or emoji.
case "$choice" in
  0) agent="codex --no-daemon" ;;
  1) agent="claude" ;;
  2) agent="opencode" ;;
  *) exit ;;
esac

sed -i \
  '/^environment {/,/^}/ s/AI_AGENT "[^"]*"/AI_AGENT "'"$agent"'"/' \
  "$config"

$TERMINAL -e $agent
