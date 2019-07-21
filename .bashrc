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
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias docker-up='sudo systemctl start docker'
alias docker-down='sudo systemctl stop docker'

GREEN="\e[32m"
CYAN="\e[36m"
END_COLOR="\e[m"
PROMPT_COMMAND='__git_ps1 "${GREEN}\u@\h:${CYAN}\w${END_COLOR}" "\n$ "'

BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

source $HOME/.base16_theme

function reload_urxvt_config() {
  cat $HOME/.vimrc_background | awk '{print $2}' | xargs -n 1 printf "#include \"$HOME/.config/base16-xresources/xresources/%s-256.Xresources\"" > $HOME/.base16_xresources

  xrdb -merge -load $HOME/.Xresources
}

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
