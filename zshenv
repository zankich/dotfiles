. "$HOME/.cargo/env"

export COMPLETION_WAITING_DOTS=true
export HYPHEN_INSENSITIVE=true

export RG_COMMAND="rg --follow --column --line-number --no-heading --smart-case --hidden --color=always --glob '!.git'"
export FZF_DEFAULT_COMMAND="fd --hidden --follow --type file --strip-cwd-prefix --color=always --exclude='.git' --exclude='go/pkg/'"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --multi --ansi --layout=reverse"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="${FZF_DEFAULT_OPTS} --preview '$HOME/.vim/plugged/fzf.vim/bin/preview.sh {}'"
export FZF_CTRL_R_OPTS="${FZF_DEFAULT_OPTS}"
export FZF_TMUX_OPTS='-p 90%,60%'

export N_PREFIX=~/.local
export GOPATH=$HOME/code/go

export MANPAGER='nvim +Man!'
export EDITOR="nvim"
export PATH=$HOME/.local/bin/dotfiles:$HOME/.local/bin:$GOPATH/bin:$PATH
# export TERM="alacritty"
export TERM="xterm-256color"

export BAT_THEME="base16-256"

export ZSH=$HOME/.oh-my-zsh

export LIBVA_DRIVER_NAME=nvidia
