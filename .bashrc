#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export LANG=en_US.UTF-8

source /usr/share/git/completion/git-prompt.sh
source $HOME/.ps1-colors
source /etc/profile.d/autojump.bash

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1

export EDITOR="nvim"

export GOROOT=$HOME/go1.10
export GOPATH=$HOME/go
export PATH=$HOME/bin:$HOME/.rbenv/bin:$GOPATH/bin:$GOROOT/bin:$PATH

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

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " [${Green}%s${Color_Off}]")\n$ '

BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

source $HOME/.base16_theme

function reload_urxvt_config() {
  cat $HOME/.vimrc_background | awk '{print $2}' | xargs -n 1 printf "#include \"$HOME/.config/base16-xresources/xresources/%s-256.Xresources\"" > $HOME/.base16_xresources

  xrdb -merge -load $HOME/.Xresources
}

function restart_compton() {
  killall compton
  compton -CGb --backend xr_glx_hybrid --vsync-use-glfinish --vsync opengl-swc
}

function reset_keyboard_settings() {
  xset r rate 200 30
  xmodmap ~/.Xmodmap
}
