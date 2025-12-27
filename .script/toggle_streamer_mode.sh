#!/bin/sh

STATE_FILE="$HOME/.streamer_mode_state"

if [ -f "$STATE_FILE" ]; then
  ln -sf "$XDG_CONFIG_HOME/alacritty/default.toml" "$XDG_CONFIG_HOME/alacritty/alacritty.toml"
  ln -sf "$XDG_CONFIG_HOME/nvim/lua/themes/gruvbox-material.lua" "$XDG_CONFIG_HOME/nvim/lua/plugins/colorschemes.lua"
  ln -sf "$XDG_CONFIG_HOME/alacritty/themes/gruvbox_material_medium_dark.toml" "$XDG_CONFIG_HOME/alacritty/themes/theme.toml"
  ln -sf "$XDG_CONFIG_HOME/polybar/themes/gruvbox-material.ini" "$XDG_CONFIG_HOME/polybar/colors.ini"
  ln -sf "$XDG_CONFIG_HOME/bspwm/themes/gruvbox-material.sh" "$XDG_CONFIG_HOME/bspwm/colors.sh"
  ln -sf "$XDG_CONFIG_HOME/wallpaper/wallhaven-2e2xyx.jpg" "$XDG_CONFIG_HOME/wallpaper/wallpaper"
  ln -sf "$XDG_CONFIG_HOME/rofi/themes/gruvbox-material.rasi" "$XDG_CONFIG_HOME/rofi/colors.rasi"
  ln -sf "$XDG_CONFIG_HOME/dunst/themes/gruvbox-material" "$XDG_CONFIG_HOME/dunst/dunstrc"
  # ln -sf "$XDG_CONFIG_HOME/Kvantum/GruvboxMaterial/kvantum.kvconfig" "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig"
  ln -sf "$XDG_CONFIG_HOME/gtk-3.0/themes/gruvbox-material/settings.ini" "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
  ln -sf "$XDG_CONFIG_HOME/gtk-4.0/themes/gruvbox-material/settings.ini" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini"
  rm "$STATE_FILE"
else
  ln -sf "$XDG_CONFIG_HOME/alacritty/streamer.toml" "$XDG_CONFIG_HOME/alacritty/alacritty.toml"
  ln -sf "$XDG_CONFIG_HOME/nvim/lua/themes/one-dark.lua" "$XDG_CONFIG_HOME/nvim/lua/plugins/colorschemes.lua"
  ln -sf "$XDG_CONFIG_HOME/alacritty/themes/one_dark.toml" "$XDG_CONFIG_HOME/alacritty/themes/theme.toml"
  ln -sf "$XDG_CONFIG_HOME/polybar/themes/one-dark.ini" "$XDG_CONFIG_HOME/polybar/colors.ini"
  ln -sf "$XDG_CONFIG_HOME/bspwm/themes/one-dark.sh" "$XDG_CONFIG_HOME/bspwm/colors.sh"
  ln -sf "$XDG_CONFIG_HOME/wallpaper/onedark.png" "$XDG_CONFIG_HOME/wallpaper/wallpaper"
  ln -sf "$XDG_CONFIG_HOME/rofi/themes/one-dark.rasi" "$XDG_CONFIG_HOME/rofi/colors.rasi"
  ln -sf "$XDG_CONFIG_HOME/dunst/themes/one-dark" "$XDG_CONFIG_HOME/dunst/dunstrc"
  # ln -sf "$XDG_CONFIG_HOME/Kvantum/OneDark/kvantum.kvconfig" "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig"
  ln -sf "$XDG_CONFIG_HOME/gtk-3.0/themes/one-dark/settings.ini" "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
  ln -sf "$XDG_CONFIG_HOME/gtk-4.0/themes/one-dark/settings.ini" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini"
  touch "$STATE_FILE"
fi

bspc wm -r
