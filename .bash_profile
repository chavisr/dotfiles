#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
	exec startx
fi

#if [ -z $WAYLAND_DISPLAY ] && [ $(tty) = /dev/tty2 ]; then
#	exec env XDG_CURRENT_DESKTOP=sway dbus-run-session sway --unsupported-gpu
#fi

#if [ -z $WAYLAND_DISPLAY ] && [ $(tty) = /dev/tty3 ]; then
#        exec env XDG_CURRENT_DESKTOP=river dbus-run-session river
#fi
