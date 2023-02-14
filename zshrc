# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="powerlevel10k/powerlevel10k"

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

export PATH=$HOME/.vim/vim-go_bin:$HOME/bin:$HOME/code/go/bin:/usr/local/go/bin:/usr/local/bin:$PATH
export GOPATH=$HOME/code/go

export TERM="xterm-256color"
export BAT_THEME="base16-256"

alias lla='ls -la'
alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"
alias rg=$RG_COMMAND

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
