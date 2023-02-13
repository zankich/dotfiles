#!/bin/bash -eu

set -o pipefail

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

  local sourcecmd='for f in ${HOME}/.zsh_configs/*; do source "${f}"; done'
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
      local bat="""$(curl -S https://api.github.com/repos/sharkdp/bat/releases/latest | jq -r '.assets | map(select(.name | test("bat.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""
      curl -SqL "$(echo "${bat}" | jq -r .browser_download_url)" | sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${bat} | jq -r .name)" .tar.gz)/bat" --strip-components=1 --no-same-owner

      local fd="""$(curl -S https://api.github.com/repos/sharkdp/fd/releases/latest | jq -r '.assets | map(select(.name | test("fd.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""
      curl -SqL "$(echo "${fd}" | jq -r .browser_download_url)" | sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${fd} | jq -r .name)" .tar.gz)/fd" --strip-components=1 --no-same-owner

      local nvim="""$(curl -S https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets | map(select(.name | test("nvim-linux64.deb"))) | .[0]')"""
      curl -SqL "$(echo "${nvim}" | jq -r .browser_download_url)" -O --output-dir ${HOME}/Downloads/
      sudo dpkg -i ${HOME}/Downloads/nvim-linux64.deb

      local go_version="$(curl -L "https://golang.org/VERSION?m=text")"
      if [[ "${go_version}" != "$(go version | cut -d ' ' -f 3)" ]]; then
        if [[ -d /usr/local/go ]]; then
          sudo rm -rf /usr/local/go
        fi

        curl -SaqL "https://dl.google.com/go/${go_version}.linux-amd64.tar.gz" | sudo tar xzv -C /usr/local
      fi

      local tmux="""$(curl -S https://api.github.com/repos/tmux/tmux/releases/latest | jq -r '.assets | map(select(.name | test("tmux.*tar.gz"))) | .[0]')"""
      local tmux_version="$(basename "$(echo ${tmux} | jq -r .name)" .tar.gz)"
      if [[ $(tmux -V | cut -d ' ' -f 2) != $(echo ${tmux_version} | cut -d '-' -f 2) ]]; then
        echo "installing new version of tmux"
        curl -SqL "$(echo "${tmux}" | jq -r .browser_download_url)" | tar zxv -C "${HOME}/Downloads/"
        sudo apt-get update && sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
        pushd "${HOME}/Downloads/${tmux_version}"
          ./configure
          make
          sudo make install
        popd
      fi
    ;;
    Darwin)
      brew install neovim tmux bat ripgrep go git fd
      brew install homebrew/cask-fonts/font-hack
    ;;
  esac

  python3 -m pip install --upgrade setuptools
  python3 -m pip install --upgrade pip
}

main() {
  setup_dependencies
  setup_colors
  setup_vim
  setup_dotfiles
}

main
