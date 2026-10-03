#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
  exec dbus-run-session -- niri --session >"$XDG_STATE_HOME/niri/session.log" 2>&1
fi
