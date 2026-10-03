#!/bin/sh

config="$HOME/.config/niri/config.kdl"
icons="$HOME/.local/share/icons/ai-menu"

choice=$(
  printf '%s\000icon\037%s\n' \
    "Codex" "$icons/codex.svg" \
    "Claude" "$icons/claude.svg" \
    "Copilot" "$icons/copilot.svg" \
    "Antigravity" "$icons/agy.svg" \
    "Grok" "$icons/grok.svg" \
    "OpenCode" "$icons/opencode.svg" |
    rofi -i -dmenu -show-icons -format i
)

# Match the zero-based menu position independently of labels and icons.
case "$choice" in
  0) agent="codex --no-daemon" ;;
  1) agent="claude" ;;
  2) agent="copilot" ;;
  3) agent="agy" ;;
  4) agent="grok" ;;
  5) agent="opencode" ;;
  *) exit ;;
esac

sed -i \
  '/^environment {/,/^}/ s/AI_AGENT "[^"]*"/AI_AGENT "'"$agent"'"/' \
  "$config"

$TERMINAL -e $agent
