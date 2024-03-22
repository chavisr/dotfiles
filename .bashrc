# git prompt
__git_branch() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local BRANCH=$(
      git symbolic-ref --short HEAD | \
      awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) ".."; else print; }'
    )
    echo " (${BRANCH})"
  fi
}
__git_status() {
  if [ -z $(__git_branch) ]; then
    return
  else
    STATUS=$(git status 2>&1)
    if [[ $STATUS = *'Untracked files'* || $STATUS = *'Changes not staged for commit'* ]]; then echo -n "?"; fi
    if [[ $STATUS = *'Changes to be committed'* ]]; then echo -n "*"; fi
    if [[ $STATUS = *'Your branch is ahead'* ]]; then echo -n "^"; fi
  fi
}
export PS1='\[\033[32m\]\u@\h \[\e[1;34m\]\w\[\e[33m\]$(__git_branch)$(__git_status) \[\e[1;35m\]λ\[\e[0m\] '

# custom alias
alias cya="systemctl poweroff"
alias reboot="systemctl reboot"
alias rand="openssl rand -hex 16"
alias code="exec code"
#alias hdmi-connect="xrandr --output HDMI-1 --mode 1920x1080 --output eDP-1 --mode 1920x1080 --brightness 0"
#alias hdmi-disconnect="xrandr --output HDMI-1 --off --output eDP-1 --mode 1920x1200 --brightness 1"
