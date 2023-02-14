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

  mkdir -p ${HOME}/.oh-my-zsh/custom/plugins/base16-shell
  ln -sf "${HOME}/.config/base16-shell/base16-shell.plugin.zsh" "${HOME}/.oh-my-zsh/custom/plugins/base16-shell/base16-shell.plugin.zsh"
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

  ln -sf "${SCRIPT_DIR}/tmux.conf" "${HOME}/.tmux.conf"
  ln -sf "${SCRIPT_DIR}/zshrc" "${HOME}/.zshrc"
  ln -sf "${SCRIPT_DIR}/p10k.zsh" "${HOME}/.p10k.zsh"
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

  if [[ ! -d ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k
  fi

  case "$(uname -s)" in
    Linux)
      sudo apt-get update
      sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config

      __zsh
      __go
      __tmux
      __bat
      __fd
      __nvim
    ;;
    Darwin)
      brew install neovim tmux bat ripgrep go git fd
      brew install homebrew/cask-fonts/font-hack
    ;;
  esac

  python3 -m pip install --upgrade setuptools
  python3 -m pip install --upgrade pip
}

__nvim() {
  echo "installing nvim..."
  local github_release="$(curl -sq https://api.github.com/repos/neovim/neovim/releases/latest)"

  if [[ "$(echo "${github_release}" | jq -r .body | grep -wc "$(nvim --version | head -n 1)")" == "0" ]]; then
    local github_asset="""$(echo "${github_release}" | \
      jq -r '.assets | map(select(.name | test("nvim-linux64.deb"))) | .[0]')"""

    curl -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" -O --output-dir ${HOME}/Downloads/
    sudo dpkg -i ${HOME}/Downloads/nvim-linux64.deb
  fi
}

__bat() {
  echo "installing bat..."
  local github_release="$(curl -sq https://api.github.com/repos/sharkdp/bat/releases/latest)"

  if [[ "$(echo "${github_release}" | jq -r .name | grep -c "$(bat --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset="""$(echo ${github_release} | \
      jq -r '.assets | map(select(.name | test("bat.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""

    curl -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${github_release} | jq -r .name)" .tar.gz)/bat" \
      --strip-components=1 --no-same-owner
  fi
}

__fd() {
  echo "installing fd..."
  local github_release="$(curl -sq https://api.github.com/repos/sharkdp/fd/releases/latest)"

  if [[ "$(echo "${github_release}" | jq -r .name | grep -c "$(fd --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset="""$(echo ${github_release} | \
      jq -r '.assets | map(select(.name | test("fd.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""

    curl -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${github_release} | jq -r .name)" .tar.gz)/fd" \
      --strip-components=1 --no-same-owner
  fi
}

__tmux() {
  echo "installing tmux..."
  local github_release="""$(curl -sq https://api.github.com/repos/tmux/tmux/releases/latest | jq -r '.assets | map(select(.name | test("tmux.*tar.gz"))) | .[0]')"""
  local tmux_version="$(basename "$(echo ${github_release} | jq -r .name)" .tar.gz)"

  if [[ $(tmux -V | cut -d ' ' -f 2) != $(echo ${tmux_version} | cut -d '-' -f 2) ]]; then
    echo "installing tmux ${tmux_version}"

    curl -#qL "$(echo "${github_release}" | jq -r .browser_download_url)" | tar zxv -C "${HOME}/Downloads/"
    pushd "${HOME}/Downloads/${tmux_version}"
      ./configure
      make -j
      sudo make install
    popd
  fi
}

__go() {
  echo "installing go..."
  local go_version="$(curl -sq "https://go.dev/VERSION?m=text")"

  if [[ "${go_version}" != "$(go version | cut -d ' ' -f 3)" ]]; then
    echo "installing go ${go_version}"
    if [[ -d /usr/local/go ]]; then
      sudo rm -rf /usr/local/go
    fi

    curl -#qL "https://dl.google.com/go/${go_version}.linux-amd64.tar.gz" | sudo tar xzv -C /usr/local
  fi
}

__zsh() {
  echo "installing zsh..."
  curl -#qL -o ${HOME}/Downloads/zsh-latest.tar.xz https://sourceforge.net/projects/zsh/files/latest/download

  pushd ${HOME}/Downloads > /dev/null
    if [[ -d ${HOME}/zsh-latest ]]; then
      rm -r zsh-latest
    fi

    mkdir -p zsh-latest

    tar -xf zsh-latest.tar.xz -C zsh-latest --strip-components=1
    pushd zsh-latest > /dev/null
      local zsh_version="$(source Config/version.mk; echo $VERSION)"
      if [[ "$(/usr/local/bin/zsh --version | cut -d ' ' -f 2)" == "${zsh_version}" ]]; then
        return 0
      fi

      ./configure
      make -j
      make test -j
      sudo make install
    popd > /dev/null
  popd > /dev/null

  if [[ $(grep -cw "/usr/local/bin/zsh" /etc/shells) == "0" ]]; then
    sudo echo "/usr/local/bin/zsh" >> /etc/shells
  fi

  chsh -s /usr/local/bin/zsh
}

main() {
  setup_dependencies
  setup_colors
  setup_vim
  setup_dotfiles
}

main
