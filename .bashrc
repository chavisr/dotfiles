#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# env
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export QT_QPA_PLATFORMTHEME=qt6ct
export EDITOR=nvim

# alias
alias l="ls -lh"
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias t="trashy"
alias clip="xclip -selection clipboard"
alias rand="openssl rand -base64 12"
alias dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias v="nvim"
alias img="nsxiv"

# quality of life
__git_ref() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local REF=$(
      git symbolic-ref --short HEAD --quiet || \
      git describe --tags --exact-match 2>/dev/null || \
      git rev-parse --short HEAD
    )
    echo " ($REF)" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) ".."; else print; }'
  fi
}

__git_status() {
  if [[ -n "$(__git_ref)" ]]; then
    local STATUS=$(git status 2>&1)
    if [[ $STATUS = *'Untracked files'* || $STATUS = *'Changes not staged for commit'* ]]; then echo -n "?"; fi
    if [[ $STATUS = *'Changes to be committed'* ]]; then echo -n "*"; fi
    if [[ $STATUS = *'Your branch is ahead'* ]]; then echo -n "^"; fi
  fi
}

# prompt
export PS1='\[\033[32m\]\u@\h \[\e[1;34m\]\w\[\e[33m\]$(__git_ref)$(__git_status) \[\e[1;35m\]>\[\e[0m\] '

# nix
if [[ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]]; then
  source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

# completion
# source <(kubectl completion bash)
# source <(podman completion bash)
# source <(trash completions bash)
