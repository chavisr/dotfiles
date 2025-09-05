#!/bin/sh

histfile="$HOME/.cache/cliphist"
placeholder="<NEWLINE>"
clipboard_cmd="xclip -o -selection clipboard"
check_interval=1  # check every n second(s)

# Ensure history file exists
[ -f "$histfile" ] || touch "$histfile"

# Normalize clipboard text (replace newlines with placeholder)
normalize() {
    echo "$1" | sed ':a;N;$!ba;s/\n/'"$placeholder"'/g'
}

# Replace placeholder with actual newlines
denormalize() {
    echo "$1" | sed "s/$placeholder/\\
/g"
}

# Add unique entry to history
add_to_history() {
    current="$1"
    normalized=$(normalize "$current")
    echo "$normalized" >> "$histfile"
}

# Clipboard watcher daemon
daemon() {

	echo -n | xclip -selection clipboard
	echo -n | xclip -selection primary
	rm $histfile

    last_clip=""
    while :; do
        current_clip=$(xclip -o -selection clipboard 2>/dev/null)

        if [ -n "$current_clip" ] && [ "$current_clip" != "$last_clip" ]; then
            add_to_history "$current_clip"
            last_clip="$current_clip"
        fi

        sleep "$check_interval"
    done
}

# Show clipboard history menu using rofi
select_from_history() {
    selection=$(tac "$histfile" | rofi -i -config $HOME/.config/rofi/config.noicon.rasi -dmenu -i -p "Clipboard history" -l 10)

    if [ -n "$selection" ]; then
        denormalize "$selection" | xclip -i -selection clipboard
        notify-send "Copied from clipboard history"
    fi
}

case "$1" in
  daemon)
    echo "Starting clipboard watcher daemon..."
    daemon
    ;;
  menu)
    select_from_history
    ;;
  help|*)
    echo "Usage:"
    echo "  $0 daemon     # Start clipboard watcher"
    echo "  $0 menu       # Show clipboard history via Rofi"
    ;;
esac
