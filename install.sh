#!/bin/bash -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

setup_colors() {
  echo "setting up colors..."
  mkdir -p ~/.config

  pushd ~/.config > /dev/null
    [[ -d "base16-shell" ]] || git clone https://github.com/tinted-theming/base16-shell
    [[ -d "base16-fzf" ]] || git clone https://github.com/tinted-theming/base16-fzf
  popd > /dev/null

  mkdir -p ~/.oh-my-zsh/plugins/base16-shell
  ln -sf ~/.config/base16-shell/base16-shell.plugin.zsh ~/.oh-my-zsh/plugins/base16-shell/base16-shell.plugin.zsh
}

setup_dotfiles() {
  echo "setting up dotfiles..."
  if [[ -d "~/.tmux/plugins/tpm" ]]; then
	  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  ln -sf ${SCRIPT_DIR}/tmux.conf ~/.tmux.conf
  ln -sf ${SCRIPT_DIR}/zshrc ~/.zshrc
  ln -sf ${SCRIPT_DIR}/vimrc ~/.vimrc
  ln -sf ${SCRIPT_DIR}/gitconfig ~/.gitconfig
  if [[ $(uname -s) == "Linux" ]]; then
    ln -sf ${SCRIPT_DIR}/logid.cfg /etc/logid.cfg
  fi

  mkdir -p ~/.config/alacritty/
  ln -sf ${SCRIPT_DIR}/alacritty.yml ~/.config/alacritty/alacritty.yml
}

setup_vim() {
  echo "setting up vim..."
  mkdir -p ~/.config
  mkdir -p ~/.vim/tmp/{backup,info,swap,undo}

  ln -sf ~/.vim ~/.config/nvim
  ln -sf ~/.vimrc ~/.config/nvim/init.vim

  if [[ -f "~/.vim/autoload/plug.vim" ]]; then
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  pip3 install -U --user pynvim
}

setup_dependencies() {
  echo "installing dependencies..."
  if [[ -d "~/.oh-my-zsh" ]]; then
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
