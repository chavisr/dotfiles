#!/bin/sh

CONFIRM_FILE='/tmp/confirm_close'
DUNST_COUNT=$(dunstctl count | grep -i current | awk '{print $3}')

if [ "$DUNST_COUNT" -eq 0 ]; then
  rm "$CONFIRM_FILE"
fi

if [ ! -f "$CONFIRM_FILE" ]; then
  touch "$CONFIRM_FILE"
  dunstify --timeout 5000 --urgency normal \
    --action='closeAction,close' 'Closing Focused Window' \
    | grep -q closeAction && bspc node -c
else
  dunstctl action
  rm "$CONFIRM_FILE"
fi
