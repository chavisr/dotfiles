#!/bin/sh

COMFIRM_FILE='/tmp/confirm_close'
DUNST_COUNT=$(dunstctl count | grep -i current | awk '{print $3}')

if [ "$DUNST_COUNT" = "0" ]; then
  rm $COMFIRM_FILE
fi

if [ ! -f $COMFIRM_FILE ]; then
  touch $COMFIRM_FILE
  dunstify --urgency normal --action="closeAction,close" "Closing Focused Window ⚠️" | \
    grep -q closeAction && bspc node -c
else
  dunstctl action
  rm $COMFIRM_FILE
fi
