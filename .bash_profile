#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z $WAYLAND_DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
  exec dbus-run-session niri --session
fi

# if [ -e /home/chavi/.nix-profile/etc/profile.d/nix.sh ]; then . /home/chavi/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
