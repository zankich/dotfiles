ZSH_THEME="frisk"

plugins=(git fzf base16-shell autojump direnv fd)

source $ZSH/oh-my-zsh.sh

source $HOME/.config/tinted-theming/base16_shell_theme
source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config

export EDITOR="nvim"

cores=""
if [[ "$(uname -s)" == "Linux" ]]; then
  cores="$(nproc --all)"
else
  cores="$(sysctl -n hw.ncpu)"
fi

export RG_COMMAND="rg --follow --column --line-number --no-heading --smart-case --hidden --color=ansi --threads $((${cores}/2))"
export FZF_DEFAULT_COMMAND="fd --hidden --follow --type file --strip-cwd-prefix --color=always --threads $((${cores}/2))"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --multi --ansi --layout=reverse --exact"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="${FZF_DEFAULT_OPTS} --preview '$HOME/.vim/plugged/fzf.vim/bin/preview.sh {}'"
export FZF_CTRL_R_OPTS="${FZF_DEFAULT_OPTS}"
export FZF_TMUX_OPTS='-p 90%,60%'

export PATH=$HOME/.vim/vim-go_bin:$HOME/bin:$HOME/code/go/bin:$HOME/bin/go/bin:/usr/local/bin:$PATH
export GOPATH=$HOME/code/go

export TERM="xterm-256color"
export BAT_THEME="base16-256"

alias lla='ls -la'
alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"
alias rg=$RG_COMMAND

# fnm
export PATH=/home/azankich/.fnm:$PATH
eval "`fnm env`"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
