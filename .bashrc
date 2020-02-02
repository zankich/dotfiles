#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export LANG=en_US.UTF-8

source /usr/share/git/completion/git-prompt.sh
source /etc/profile.d/autojump.bash

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1

export EDITOR="nvim"

export GOPATH=$HOME/go
export PATH=$HOME/bin:$HOME/.rbenv/bin:$GOPATH/bin:$PATH

eval "$(rbenv init -)"
eval "$(direnv hook bash)"

alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias vim="nvim"
alias vimdiff="nvim -d"
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'
alias docker-up='sudo systemctl start docker'
alias docker-down='sudo systemctl stop docker'

RED="\[\e[0;31m\]"
GREEN="\[\e[0;32m\]"
BLUE="\[\e[0;34m\]"
PURPLE="\[\e[0;35m\]"
YELLOW="\[\e[0;33m\]"
CYAN="\[\e[0;36m\]"
END_COLOR="\[\e[m\]"
PROMPT_COMMAND='__git_ps1 "${GREEN}\u@\h:${CYAN}\w${END_COLOR}" "\n${YELLOW}$(date "+%D %T")${END_COLOR} ${PURPLE}>${END_COLOR} "'

BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

source $HOME/.base16_theme

function restart_compton() {
  killall compton
  compton -CGb --backend glx --vsync
}

function reset_keyboard_settings() {
  xset r rate 200 30
  xmodmap ~/.Xmodmap
}

function stop_hiss() {
  amixer -c 0 set 'Headphone Mic Boost',0 1
}
