#!/bin/bash -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

setup_colors() {
  echo "setting up colors..."
  mkdir -p ${HOME}/.config

  pushd ${HOME}/.config > /dev/null
    if [[ -d "base16-shell" ]]; then
      pushd base16-shell > /dev/null
        git pull -r
      popd > /dev/null
    else
      git clone https://github.com/tinted-theming/base16-shell
    fi

    if [[ -d "base16-fzf" ]]; then
      pushd base16-fzf > /dev/null
        git pull -r
      popd > /dev/null
    else
      git clone https://github.com/tinted-theming/base16-fzf
    fi
  popd > /dev/null

  mkdir -p ${HOME}/.oh-my-zsh/plugins/base16-shell
  ln -sf "${HOME}/.config/base16-shell/base16-shell.plugin.zsh" "${HOME}/.oh-my-zsh/plugins/base16-shell/base16-shell.plugin.zsh"
}

setup_dotfiles() {
  echo "setting up dotfiles..."
  if [[ -d "${HOME}/.tmux/plugins/tpm" ]]; then
    pushd ${HOME}/.tmux/plugins/tpm > /dev/null
      git pull -r
    popd > /dev/null
  else
    git clone https://github.com/tmux-plugins/tpm
  fi

  mkdir -p "${HOME}/.zsh_configs"

  local sourcecmd='for f in ~/.zsh_configs/*; do source "${f}"; done'
  if [[ $(grep -c "${sourcecmd}" $HOME/.zshrc) == "0" ]];then
    echo "# added by zankich dotfiles" >> $HOME/.zshrc
    echo "${sourcecmd}" >> $HOME/.zshrc
  fi

  ln -sf "${SCRIPT_DIR}/tmux.conf" "${HOME}/.tmux.conf"
  ln -sf "${SCRIPT_DIR}/zshrc" "${HOME}/.zsh_configs/zshrc"
  ln -sf "${SCRIPT_DIR}/vimrc" "${HOME}/.vimrc"
  ln -sf "${SCRIPT_DIR}/gitconfig" "${HOME}/.gitconfig"

  if [[ $(uname -s) == "Linux" ]]; then
    sudo ln -sf ${SCRIPT_DIR}/logid.cfg /etc/logid.cfg
  fi

  mkdir -p ${HOME}/.config/alacritty/
  ln -sf ${SCRIPT_DIR}/alacritty.yml ${HOME}/.config/alacritty/alacritty.yml
}

setup_vim() {
  echo "setting up vim..."
  mkdir -p ${HOME}/.config
  mkdir -p ${HOME}/.vim/tmp/{backup,info,swap,undo}

  ln -sf "${HOME}/.vim" "${HOME}/.config/nvim"
  ln -sf "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"

  if [[ ! -f "${HOME}/.vim/autoload/plug.vim" ]]; then
    curl -fLo ${HOME}/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  pip3 install -U --user pynvim
}

setup_dependencies() {
  echo "installing dependencies..."
  if [[ ! -d ${HOME}/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  case "$(uname -s)" in
    Linux)
    ;;
    Darwin)
      brew install neovim tmux bat fnm ripgrep go git
      python3 -m pip install --upgrade setuptools
      python3 -m pip install --upgrade pip
      brew install homebrew/cask-fonts/font-hack
    ;;
  esac
}

main() {
  setup_dependencies
  setup_colors
  setup_vim
  setup_dotfiles
}

main
