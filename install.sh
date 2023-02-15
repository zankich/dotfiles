#!/bin/bash -eu

set -o pipefail

TMP_DIR="$(mktemp -d)"
trap "rm -rf ${TMP_DIR}" EXIT

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITHUB_CURL_HEADERS="--header \"Accept: application/vnd.github+json\""

if [[ ${GITHUB_API_TOKEN:+1} ]]; then
  GITHUB_CURL_HEADERS="${GITHUB_CURL_HEADERS} --header \"Authorization: Bearer ${GITHUB_API_TOKEN}\""
fi

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
    git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm
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
    curl --fail-with-body -qLo ${HOME}/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
}

setup_dependencies() {
  echo "installing dependencies..."
  case "$(uname -s)" in
    Linux)
      sudo apt-get update && \
      sudo apt-get install -y \
        libevent-dev \
        ncurses-dev \
        build-essential \
        bison \
        pkg-config \
        curl \
        git \
        jq \
        python3 \
        python3-pip \
        cmake \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxcb-xfixes0-dev \
        libxkbcommon-dev \
        automake \
        gettext \
        libtool-bin \
        locales \
        ninja-build \
        unzip \
        autoconf \
        ripgrep \
        autojump

      __go
      __rust
      __zsh
      __tmux
      __bat
      __fd
      __nvim
      __alacritty
      __direnv
      __grpcurl
    ;;
    Darwin)
      if ! command -v brew > /dev/null; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl --fail-with-body -q -sSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      brew install \
        neovim \
        tmux \
        bat \
        ripgrep \
        go \
        git \
        fd \
        zsh \
        curl \
        jq \
        autojump \
        direnv \
        grpcurl

      brew install homebrew/cask-fonts/font-hack
      brew install --cask alacritty

      __rust
    ;;
  esac

  python3 -m pip install --upgrade --user pip
  python3 -m pip install --upgrade --user setuptools
  python3 -m pip install --upgrade --user pynvim

  if [[ ! -d ${HOME}/.oh-my-zsh ]]; then
    sh -c "$(curl --fail-with-body -q -sSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  if [[ ! -d ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k
  else
    pushd ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k > /dev/null
      git pull -r
    popd > /dev/null
  fi
}

__nvim() {
  echo "installing nvim..."
  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/neovim/neovim/releases/latest)"

  if ! command -v nvim > /dev/null || [[ $(echo "${github_release}" | jq -r .body | grep -wc "$(nvim --version | head -n 1)") == "0" ]]; then

    mkdir -p ${TMP_DIR}/nvim

    pushd  ${TMP_DIR}/nvim > /dev/null
      curl --fail-with-body -#qL "https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz" | \
        tar zxv --strip-components=1

      make CMAKE_BUILD_TYPE=Release
      sudo make install
    popd > /dev/null
  fi
}

__bat() {
  echo "installing bat..."
  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/sharkdp/bat/releases/latest)"

  if ! command -v bat > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(bat --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset="""$(echo ${github_release} | \
      jq -r '.assets | map(select(.name | test("bat.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${github_asset} | jq -r .name)" .tar.gz)/bat" \
      --strip-components=1 --no-same-owner
  fi
}

__fd() {
  echo "installing fd..."
  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/sharkdp/fd/releases/latest)"

  if ! command -v fd > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(fd --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset="""$(echo ${github_release} | \
      jq -r '.assets | map(select(.name | test("fd.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo ${github_asset} | jq -r .name)" .tar.gz)/fd" \
      --strip-components=1 --no-same-owner
  fi
}

__tmux() {
  echo "installing tmux..."
  local github_release="""$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/tmux/tmux/releases/latest | jq -r '.assets | map(select(.name | test("tmux.*tar.gz"))) | .[0]')"""
  local tmux_version="$(basename "$(echo ${github_release} | jq -r .name)" .tar.gz)"

  if ! command -v tmux > /dev/null || [[ $(tmux -V | cut -d ' ' -f 2) != $(echo ${tmux_version} | cut -d '-' -f 2) ]]; then
    echo "installing tmux ${tmux_version}"

    curl --fail-with-body -#qL "$(echo "${github_release}" | jq -r .browser_download_url)" | tar zxv -C "${TMP_DIR}/"
    pushd "${TMP_DIR}/${tmux_version}"
      ./configure
      make -j
      sudo make install
    popd
  fi
}

__go() {
  echo "installing go..."
  local go_version="$(curl --fail-with-body -sq "https://go.dev/VERSION?m=text")"

  if ! command -v go > /dev/null || [[ "${go_version}" != "$(go version | cut -d ' ' -f 3)" ]]; then
    echo "installing go ${go_version}"
    if [[ -d /usr/local/go ]]; then
      sudo rm -rf /usr/local/go
    fi

    local arch="amd64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    curl --fail-with-body -#qL "https://dl.google.com/go/${go_version}.linux-${arch}.tar.gz" | sudo tar xzv -C /usr/local
  fi
}

__zsh() {
  echo "installing zsh..."
  curl --fail-with-body -#qL -o ${TMP_DIR}/zsh-latest.tar.xz https://sourceforge.net/projects/zsh/files/latest/download

  mkdir -p ${TMP_DIR}/zsh-latest

  pushd ${TMP_DIR} > /dev/null
    tar -xf zsh-latest.tar.xz -C zsh-latest --strip-components=1
    pushd zsh-latest > /dev/null
      local zsh_version="$(source Config/version.mk; echo $VERSION)"
      if ! command -v /usr/local/bin/zsh > /dev/null || [[ "$(/usr/local/bin/zsh --version | cut -d ' ' -f 2)" != "${zsh_version}" ]]; then
        ./configure
        make -j
        sudo make install
      fi
    popd > /dev/null
  popd > /dev/null

  if [[ $(grep -cw "/usr/local/bin/zsh" /etc/shells) == "0" ]]; then
    sudo echo "/usr/local/bin/zsh" >> /etc/shells
  fi

  chsh -s /usr/local/bin/zsh
}

__rust() {
  echo "installing rust..."
  if ! command -v rustup > /dev/null; then
    curl --fail-with-body --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh -s -- -y
  fi

  source "$HOME/.cargo/env"

  rustup override set stable
  rustup update stable
}

__alacritty() {
  echo "installing alacritty..."
  if ! command -v Xorg; then
    echo "no xserver installed skipping installation..."
    return 0
  fi

  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/alacritty/alacritty/releases/latest)"
  local alacritty_version="$(echo "${github_release}" | jq -r .tag_name)"

  if ! command -v alacritty > /dev/null || [[ "$(echo "${alacritty_version}" | grep -c "$(alacritty --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset="""$(echo ${github_release} | \
      jq -r '.assets | map(select(.name | test("bat.*-x86_64-unknown-linux-musl.tar.gz"))) | .[0]')"""

    mkdir -p ${TMP_DIR}/alacritty

    pushd  ${TMP_DIR} > /dev/null
      curl --fail-with-body -#qL "https://github.com/alacritty/alacritty/archive/refs/tags/${alacritty_version}.tar.gz" | \
        tar zxv -C alacritty --strip-components=1

      pushd alacritty > /dev/null
        cargo build --release

        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
        sudo cp target/release/alacritty /usr/local/bin # or anywhere else in $PATH
        sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
        sudo desktop-file-install extra/linux/Alacritty.desktop
        sudo update-desktop-database

        sudo mkdir -p /usr/local/share/man/man1
        gzip -c extra/alacritty.man | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
        gzip -c extra/alacritty-msg.man | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null

        mkdir -p ${ZDOTDIR:-~}/.zsh_functions
        'fpath+=${ZDOTDIR:-~}/.zsh_functions' >> ${ZDOTDIR:-~}/.zshrc
        cp extra/completions/_alacritty ${ZDOTDIR:-~}/.zsh_functions/_alacritty
      popd > /dev/null
    popd > /dev/null
  fi
}

__direnv() {
  echo "installing direnv..."
  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/direnv/direnv/releases/latest)"
  local direnv_version="$(echo "${github_release}" | jq -r .tag_name)"

  if ! command -v direnv > /dev/null || [[ "$(echo "${direnv_version}" | grep -c $(direnv --version))" == "0" ]]; then
    local arch="amd64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    sudo curl --fail-with-body -#qL -o /usr/local/bin/direnv https://github.com/direnv/direnv/releases/download/${direnv_version}/direnv.linux-${arch}
    sudo chmod +x /usr/local/bin/direnv
  fi
}

__grpcurl() {
  echo "installing grpcurl..."
  local github_release="$(curl ${GITHUB_CURL_HEADERS} --fail-with-body -sq https://api.github.com/repos/fullstorydev/grpcurl/releases/latest)"

  if ! command -v grpcurl > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(grpcurl --version)")" == "0" ]]; then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    local github_asset="""$(echo ${github_release} | \
      jq -r --arg arch "$arch" ".assets | map(select(.name | test(\"grpcurl_.*_linux_$arch.tar.gz\"))) | .[0]")"""

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin grpcurl --no-same-owner
  fi
}

main() {
  setup_dependencies
  setup_colors
  setup_vim
  setup_dotfiles
}

main
