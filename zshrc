# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git fzf base16-shell autojump direnv fd golang rust tmux sudo docker docker-compose zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
source $HOME/.config/tinted-theming/base16_shell_theme
source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config

cores=""
if [[ "$(uname -s)" == "Linux" ]]; then
  cores="$(nproc --all)"
else
  export HOMEBREW_NO_ANALYTICS=1
  export LS_COLORS=$LSCOLORS
  cores="$(sysctl -n hw.ncpu)"
fi

export EDITOR="nvim"
export RG_COMMAND="rg --follow --column --line-number --no-heading --smart-case --hidden --color=ansi --threads=$((${cores}/2)) --glob '!.git' "
export FZF_DEFAULT_COMMAND="fd --hidden --follow --type file --strip-cwd-prefix --color=always --threads=$((${cores}/2)) --exclude=".git" --exclude="go/pkg/""
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --multi --ansi --layout=reverse"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="${FZF_DEFAULT_OPTS} --preview '$HOME/.vim/plugged/fzf.vim/bin/preview.sh {}'"
export FZF_CTRL_R_OPTS="${FZF_DEFAULT_OPTS}"
export FZF_TMUX_OPTS='-p 90%,60%'

export PATH=$HOME/.vim/vim-go_bin:$HOME/bin:$HOME/code/go/bin:/usr/local/bin:$PATH
export GOPATH=$HOME/code/go

export TERM="xterm-256color"
export BAT_THEME="base16-256"

alias lla='ls -la'
alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"
alias rg=$RG_COMMAND
alias chmox="chmod +x"

[[ ! -f ~/.cargo/env ]] || source ~/.cargo/env

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=(~/.zsh_functions)
fpath+=(~/.oh-my-zsh/custom/plugins/zsh-completions/src)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept  # space + tab  | autosuggest


_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

_get_display() {
  if [ "$(uname -s)" != "Linux" ]; then
    return
  fi

  local pid
  pid="$(pgrep --newest --uid $(id -u) gnome-session)"
  if [ -n "${pid}" ]; then
    export DISPLAY="$(awk 'BEGIN{FS="="; RS="\0"}  $1=="DISPLAY" {print $2; exit}' /proc/${pid}/environ)"
  fi
}

_get_display
