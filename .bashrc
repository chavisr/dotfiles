#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# xdg
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

# alias
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias rand="openssl rand -hex 16"
alias code="exec code"
alias dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias nano="micro"
alias vim="nvim"
alias v="nvim"

# quality of life
__git_ref() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local REF=$(
      git symbolic-ref --short HEAD -q || \
      git describe --tags --exact-match 2>/dev/null || \
      git rev-parse --short HEAD
    )
    echo " (${REF})" | awk -v len=10 '{ if (length($0) > len) print substr($0, 1, len-3) ".."; else print; }'
  fi
}
__git_status() {
  if [ -z "$(__git_ref)" ]; then
    return
  else
    STATUS=$(git status 2>&1)
    if [[ $STATUS = *'Untracked files'* || $STATUS = *'Changes not staged for commit'* ]]; then echo -n "?"; fi
    if [[ $STATUS = *'Changes to be committed'* ]]; then echo -n "*"; fi
    if [[ $STATUS = *'Your branch is ahead'* ]]; then echo -n "^"; fi
  fi
}

# prompt
PS1='\[\033[32m\]\u@\h \[\e[1;34m\]\w\[\e[33m\]$(__git_ref)$(__git_status) \[\e[1;35m\]>\[\e[0m\] '

# completion
# source <(kubectl completion bash)
# source <(podman completion bash)
