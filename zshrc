# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
#
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git fzf base16-shell direnv fd golang rust tmux sudo docker docker-compose zsh-syntax-highlighting zsh-autosuggestions brew zoxide sdk)
#
fpath+=(
  ~/.zsh_functions
  ${ZSH}/custom/plugins/zsh-completions/src
  ${ZSH}/custom/completions
)
#
source $ZSH/oh-my-zsh.sh
#
# # colors
# # force fzf theme change
source $HOME/.config/tinted-theming/base16_shell_theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.sdkman/bin/sdkman-init.sh ]] || source ~/.sdkman/bin/sdkman-init.sh
[[ ! -f ~/.cargo/env ]] || source ~/.cargo/env

bindkey '^ ' autosuggest-accept  # space + tab  | autosuggest
#
alias lla='ls -la'
alias nvimdiff="nvim -d"
alias rg=$RG_COMMAND
alias chmox="chmod +x"
alias nvi="command nvim -u NONE"
alias j="z"
alias ssh="TERM=xterm ssh"
alias zankich_clone='GIT_SSH_COMMAND="ssh -i ~/.ssh/id_zankich_github -o IdentitiesOnly=yes" git clone'

if [[ "$(uname -s)" == "Darwin" ]]; then
 export HOMEBREW_NO_ANALYTICS=1
else
  alias pbpaste='xclip -selection clipboard -o'
  pbcopy() {
    # copy to osc52
    local input=$(cat)
    local encoded=$(printf "$input" | base64 | tr -d '\n')

    if [[ -z "$encoded" ]]; then
      return
    fi

    # Check if we are running in a terminal
    if [ -t 1 ]; then
      printf "\033]52;c;$encoded\007"
    else
      printf "\033Ptmux;\033\033]52;c;$encoded\007\033\\"
    fi
  }
fi

dkar() {
  bash -c '
  docker_ps=$(docker ps -qa)
  if [[ -n "${docker_ps}" ]]; then
    echo "docker kill"
    docker kill ${docker_ps}
  fi

  docker_containers=$(docker container ls -aq)
  if [[ -n "${docker_containers}" ]]; then
    echo "docker rm"
    docker rm --volumes ${docker_containers}
  fi
  '
}

help() {
  bash -c "help ${1}"
}

nvim() {
  mkdir -p "${HOME}/.cache/nvim/listen/"

  local socket
  socket="${HOME}/.cache/nvim/listen/$(date +%s).pipe"
  trap "rm -f -- ${socket}" EXIT

  command nvim --listen "${socket}" "${@}"
}


_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

fzf() {
  source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config
  command fzf "${@}"
}

fzf-tmux() {
  source $HOME/.config/base16-fzf/bash/base16-$(cat $HOME/.config/tinted-theming/theme_name).config
  command fzf-tmux "${@}"
}

idea() {
  command idea ${1:=.} &> /dev/null &
  disown
}

goland() {
  command goland ${1:=.} &> /dev/null &
  disown
}

nflxgrpcurl() {
  grpcurl -servername localserver.us-east-1.test.stub.metatron.netflix.net -cert ~/.metatron/certificates/user.crt -key ~/.metatron/certificates/user.key -cacert ~/.metatron/certificates/localServer.pem.crt "${@}"
}

# #https://wiki.archlinux.org/title/zsh#On-demand_rehash
# if [[ "$(uname -s)" != "Darwin" ]]; then
#   autoload -Uz add-zsh-hook
#
#   rehash_precmd() {
#     mkdir -p /tmp/cache/zsh/pacman
#
#     local paccache_time="$(date -r /tmp/cache/zsh/pacman +%s%N)"
#     if (( zshcache_time < paccache_time )); then
#       rehash
#       zshcache_time="$paccache_time"
#       # set-x-env.sh
#     fi
#   }
#
#   add-zsh-hook -Uz precmd rehash_precmd
# fi
#
xset r rate 200 30
