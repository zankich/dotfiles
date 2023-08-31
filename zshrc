# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
 export HOMEBREW_NO_ANALYTICS=1
fi

export N_PREFIX=~/.local

export ZSH_PYENV_QUIET="true"
export COMPLETION_WAITING_DOTS=true
export HYPHEN_INSENSITIVE=true

export RG_COMMAND="rg --follow --column --line-number --no-heading --smart-case --hidden --color=always --glob '!.git'"

export FZF_DEFAULT_COMMAND="fd --hidden --follow --type file --strip-cwd-prefix --color=always --exclude='.git' --exclude='go/pkg/'"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --multi --ansi --layout=reverse"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="${FZF_DEFAULT_OPTS} --preview '$HOME/.vim/plugged/fzf.vim/bin/preview.sh {}'"
export FZF_CTRL_R_OPTS="${FZF_DEFAULT_OPTS}"
export FZF_TMUX_OPTS='-p 90%,60%'

export GOPATH=$HOME/code/go

export EDITOR="nvim"
export PATH=$HOME/bin:$HOME/.local/bin:$GOPATH/bin:$PATH
export TERM="xterm-256color"

export BAT_THEME="base16-256"

export ZSH=$HOME/.oh-my-zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git fzf base16-shell direnv fd golang rust tmux sudo docker docker-compose zsh-syntax-highlighting zsh-autosuggestions brew pyenv rbenv zoxide sdk)

source $ZSH/oh-my-zsh.sh

# colors
source $HOME/.config/tinted-theming/base16_shell_theme
# force fzf theme change
fzf() {
  source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config
  command fzf "${@}"
}

fzf-tmux() {
  source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config
  command fzf-tmux "${@}"
}

nvim() {
  # local socket
  # socket="${HOME}/.cache/nvim/listen/socket"
  #
  # if [[ -e "${socket}" ]];then
  #   if [[ -n "${TMUX}" ]]; then
  #     local ids window_id pane_id
  #
  #     ids="$(tmux list-panes -a -F '#{pane_current_command} #{window_id} #{pane_id}' | awk '/^nvim / {print $2" "$3; exit}')"
  #     window_id="$ids[(w)1]"
  #     pane_id="$ids[(w)2]"
  #
  #     [[ -n "$pane_id" ]] && tmux select-window -t "$window_id" && tmux select-pane -t "$pane_id"
  #   fi
  #
  #   command nvim --server "${socket}" --remote-tab-silent "${@}"
  # else
  #   command nvim --listen "${socket}" "${@}"
  # fi

  mkdir -p "${HOME}/.cache/nvim/listen/"

  local socket
  socket="${HOME}/.cache/nvim/listen/$(date +%s).pipe"
  command nvim --listen "${socket}" "${@}"

  rm "${pipe}" >& /dev/null || true
}

[[ ! -f ~/.cargo/env ]] || source ~/.cargo/env
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=(~/.zsh_functions)
fpath+=(~/.oh-my-zsh/custom/plugins/zsh-completions/src)
bindkey '^ ' autosuggest-accept  # space + tab  | autosuggest

alias lla='ls -la'
# alias nvim="nvim --listen $HOME/.cache/nvim/listen/$(date +%s).pipe"
alias vimdiff="nvim -d"
alias rg=$RG_COMMAND
alias chmox="chmod +x"
alias nvim-no-config="command nvim -u NONE"
alias j="z"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

bash_help() {
  bash -c "help ${1}"
}

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

ulimit -n 4096
