#!/bin/bash

set -eu -o pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf ${TMP_DIR}' EXIT

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITHUB_CURL_HEADERS=(--header "Accept: application/vnd.github+json")

if [[ ${GITHUB_API_TOKEN:+1} ]]; then
  GITHUB_CURL_HEADERS+=(--header "Authorization: Bearer ${GITHUB_API_TOKEN}")
fi

setup_colors() {
  echo "setting up colors..."
  mkdir -p "${HOME}/.config"

  __ensure_repo https://github.com/tinted-theming/base16-shell "${HOME}/.config/base16-shell"
  __ensure_repo https://github.com/tinted-theming/base16-fzf "${HOME}/.config/base16-fzf"

  mkdir -p "${HOME}/.oh-my-zsh/custom/plugins/base16-shell"
  ln -sf "${HOME}/.config/base16-shell/base16-shell.plugin.zsh" "${HOME}/.oh-my-zsh/custom/plugins/base16-shell/base16-shell.plugin.zsh"

  if [ ! -f "${HOME}/.config/tinted-theming/base16_shell_theme" ]; then
    bash -x -c "shopt -s expand_aliases; . $HOME/.config/base16-shell/profile_helper.sh; set_theme default-dark;"
  fi

}

setup_dotfiles() {
  echo "setting up dotfiles..."
  mkdir -p "${HOME}/.tmux/plugins/"
  mkdir -p "${HOME}/.config/alacritty"

  ln -sf "${SCRIPT_DIR}/tmux.conf" "${HOME}/.tmux.conf"
  ln -sf "${SCRIPT_DIR}/zshrc" "${HOME}/.zshrc"
  ln -sf "${SCRIPT_DIR}/p10k.zsh" "${HOME}/.p10k.zsh"
  ln -sf "${SCRIPT_DIR}/vimrc" "${HOME}/.vimrc"
  ln -sf "${SCRIPT_DIR}/gitconfig" "${HOME}/.gitconfig"
  ln -sf "${SCRIPT_DIR}/alacritty.yml" "${HOME}/.config/alacritty/alacritty.yml"
  ln -sf "${SCRIPT_DIR}/scripts/tmux/" "${HOME}/.tmux/scripts"

  if [[ "$(uname -s)" == "Linux" ]]; then
    sudo ln -sf "${SCRIPT_DIR}/logid.cfg" /etc/logid.cfg
  fi

  __ensure_repo https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"

  tmux -c 'bash -e -c "~/.tmux/plugins/tpm/bin/install_plugins" '
  tmux -c 'bash -e -c "~/.tmux/plugins/tpm/bin/update_plugins all"'
}

setup_vim() {
  echo "setting up vim..."
  mkdir -p "${HOME}/.config"
  mkdir -p "${HOME}/.vim/tmp/{backup,info,swap,undo}"

  ln -sf "${HOME}/.vim" "${HOME}/.config/nvim"
  ln -sf "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"

  if [[ ! -f "${HOME}/.vim/autoload/plug.vim" ]]; then
    curl --fail-with-body -qLo "${HOME}/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  nvim +PlugInstall +qa
  nvim +PlugInstall! +PlugUpgrade +qa
  ~/.fzf/install --all
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
        autojump \
        xclip \
        libudev-dev \
        libconfig++-dev \
        libevdev-dev \
        xsel \
        fonts-hack-ttf \
        libpixman-1-dev \
        libslirp-dev \
        libssh-dev \
        libgtk-3-dev

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
      __logiops
      __qemu "7.2.0"
      __colima
      __lima
      __docker
    ;;
    Darwin)
      if ! command -v brew > /dev/null; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl --fail-with-body -q -sSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew analytics off

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
        grpcurl \
        reattach-to-user-namespace

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

  __ensure_repo https://github.com/romkatv/powerlevel10k "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
  __ensure_repo https://github.com/zsh-users/zsh-syntax-highlighting "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  __ensure_repo https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  __ensure_repo https://github.com/zsh-users/zsh-completions "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"
}

__nvim() {
  echo "installing nvim..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/neovim/neovim/releases/latest)"

  if ! command -v nvim > /dev/null || [[ $(echo "${github_release}" | jq -r .body | grep -wc "$(nvim --version | head -n 1)") == "0" ]]; then

    mkdir -p "${TMP_DIR}/nvim"

    pushd  "${TMP_DIR}/nvim" > /dev/null
      curl --fail-with-body -#qL "https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz" | \
        tar zxv --strip-components=1

      make CMAKE_BUILD_TYPE=Release
      sudo make install
    popd > /dev/null
  fi
}

__bat() {
  echo "installing bat..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/sharkdp/bat/releases/latest)"

  if ! command -v bat > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(bat --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset
    github_asset="""$(echo "${github_release}" | \
      jq --arg arch "$(uname -m)" -r '.assets | map(select(.name | contains($arch) and contains("linux"))) | .[0]')"""

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo "${github_asset}" | jq -r .name)" .tar.gz)/bat" \
      --strip-components=1 --no-same-owner
  fi
}

__fd() {
  echo "installing fd..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/sharkdp/fd/releases/latest)"

  if ! command -v fd > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(fd --version | cut -d " " -f 2)")" == "0" ]]; then
    local github_asset
    github_asset="""$(echo "${github_release}" | \
      jq --arg arch "$(uname -m)" -r '.assets | map(select(.name | contains($arch) and contains("linux"))) | .[0]')"""

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin "$(basename "$(echo "${github_asset}" | jq -r .name)" .tar.gz)/fd" \
      --strip-components=1 --no-same-owner
  fi
}

__tmux() {
  echo "installing tmux..."
  local github_release
  github_release="""$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/tmux/tmux/releases/latest | jq -r '.assets | map(select(.name | test("tmux.*tar.gz"))) | .[0]')"""
  local tmux_version
  tmux_version="$(basename "$(echo "${github_release}" | jq -r .name)" .tar.gz)"

  if ! command -v tmux > /dev/null || [[ "$(tmux -V | cut -d ' ' -f 2)" != "$(echo "${tmux_version}" | cut -d '-' -f 2)" ]]; then
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
  local go_version
  go_version="$(curl --fail-with-body -sq "https://go.dev/VERSION?m=text")"

  if ! command -v /usr/local/bin/go > /dev/null || [[ "${go_version}" != "$(/usr/local/bin/go version | cut -d ' ' -f 3)" ]]; then
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

  sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
  sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
}

__zsh() {
  echo "installing zsh..."
  curl --fail-with-body -#qL -o "${TMP_DIR}/zsh-latest.tar.xz" https://sourceforge.net/projects/zsh/files/latest/download

  mkdir -p "${TMP_DIR}/zsh-latest"

  pushd "${TMP_DIR}" > /dev/null
    tar -xf zsh-latest.tar.xz -C zsh-latest --strip-components=1
    pushd zsh-latest > /dev/null
      local zsh_version
      zsh_version="$(grep "VERSION=" Config/version.mk | cut -d"=" -f2)"

      if ! command -v /usr/local/bin/zsh > /dev/null || [[ "$(/usr/local/bin/zsh --version | cut -d ' ' -f 2)" != "${zsh_version}" ]]; then
        ./configure
        make -j
        sudo make install
      fi
    popd > /dev/null
  popd > /dev/null

  if [[ $(grep -cw "/usr/local/bin/zsh" /etc/shells) == "0" ]]; then
    echo "/usr/local/bin/zsh" | sudo tee -a /etc/shells
  fi

  chsh -s /usr/local/bin/zsh
}

__rust() {
  echo "installing rust..."
  if ! command -v rustup > /dev/null; then
    curl --fail-with-body --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh -s -- -y
  fi

  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"

  rustup override set stable
  rustup update stable
}

__alacritty() {
  echo "installing alacritty..."
  if ! command -v Xorg; then
    echo "no xserver installed skipping installation..."
    return 0
  fi

  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/alacritty/alacritty/releases/latest)"
  local alacritty_version
  alacritty_version="$(echo "${github_release}" | jq -r .tag_name)"

  if ! command -v alacritty > /dev/null || [[ "$(echo "${alacritty_version}" | grep -c "$(alacritty --version | cut -d " " -f 2)")" == "0" ]]; then
    mkdir -p "${TMP_DIR}/alacritty"

    pushd  "${TMP_DIR}" > /dev/null
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

        mkdir -p "${HOME}/.zsh_functions"
        cp extra/completions/_alacritty "${HOME}/.zsh_functions/_alacritty"
      popd > /dev/null
    popd > /dev/null
  fi
}

__direnv() {
  echo "installing direnv..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/direnv/direnv/releases/latest)"
  local direnv_version
  direnv_version="$(echo "${github_release}" | jq -r .tag_name)"

  if ! command -v direnv > /dev/null || [[ "$(echo "${direnv_version}" | grep -c "$(direnv --version)")" == "0" ]]; then
    local arch="amd64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    sudo curl --fail-with-body -#qL -o /usr/local/bin/direnv https://github.com/direnv/direnv/releases/download/"${direnv_version}"/direnv.linux-${arch}
    sudo chmod +x /usr/local/bin/direnv
  fi
}

__grpcurl() {
  echo "installing grpcurl..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/fullstorydev/grpcurl/releases/latest)"

  if ! command -v grpcurl > /dev/null || [[ "$(echo "${github_release}" | jq -r .tag_name | grep -c "$(grpcurl --version)")" == "0" ]]; then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    local github_asset
    github_asset="$(echo "${github_release}" | \
      jq -r --arg arch "${arch}" '.assets | map(select(.name | contains($arch) and contains("linux"))) | .[0]')"

    curl --fail-with-body -#qL "$(echo "${github_asset}" | jq -r .browser_download_url)" | \
      sudo tar zxv -C /usr/local/bin grpcurl --no-same-owner
  fi
}

__logiops() {
  echo "installing logiops..."

  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/PixlOne/logiops/releases/latest)"
  local logiops_version
  logiops_version="$(echo "${github_release}" | jq -r .tag_name)"

    __ensure_repo https://github.com/PixlOne/logiops "${TMP_DIR}/logiops"
    pushd "${TMP_DIR}/logiops" > /dev/null
      git fetch --all --tags
      git checkout "${logiops_version}"
      if ! command -v logid > /dev/null || [[ $(logid --version | awk -F "-g" '{print $2}' | grep -c "$(git rev-parse --short  HEAD)") == 0 ]]; then
        mkdir -p build
        pushd build > /dev/null
          cmake ..
          make
          sudo make install
        popd > /dev/null

        if systemctl --version; then
          sudo systemctl enable --now logid
          sudo systemctl restart logid
        fi
      fi
    popd > /dev/null
}

__qemu() {
  local version
  version="${1}"; shift;
  echo "installing qemu..."

  if ! command -v qemu-aarch64 > /dev/null || [[ "$(grep -c "$(qemu-aarch64 --version | head -n 1 | cut -d" " -f 3)" "${version}" )" == "0" ]]; then
    mkdir -p "${TMP_DIR}/qemu"
    pushd "${TMP_DIR}/qemu" > /dev/null
      curl -OL "https://download.qemu.org/qemu-${version}.tar.xz"
      tar xvJf "qemu-${version}.tar.xz"
      cd "qemu-${version}"
      ./configure \
        --enable-slirp \
        --enable-linux-user \
        --enable-curses \
        --enable-libssh \
        --enable-gtk
      make -j "$(nproc)"
      sudo make install
    popd > /dev/null
  fi
}

__colima() {
  echo "installing colima..."
  local github_release
  github_release="$(curl "${GITHUB_CURL_HEADERS[@]}" --fail-with-body -sq https://api.github.com/repos/abiosoft/colima/releases/latest)"
  local version
  version="$(echo "${github_release}" | jq -r .tag_name)"

  if ! command -v colima > /dev/null || [[ "$(echo "${version}" | grep -c "$(colima --version | cut -d " " -f 3)")" == "0" ]]; then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="aarch64"
    fi

    sudo curl --fail-with-body -#qL -o /usr/local/bin/colima https://github.com/abiosoft/colima/releases/download/"${version}"/colima-Linux-"${arch}"
    sudo chmod +x /usr/local/bin/colima
  fi
}

__lima() {
  echo "installing lima..."
  local version
  version=$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest | jq -r .tag_name)


  if ! command -v limactl > /dev/null || [[ "$(echo "${version}" | grep -c "$(limactl --version | cut -d " " -f 3)")" == "0" ]]; then
    curl --fail-with-body -#qL "https://github.com/lima-vm/lima/releases/download/${version}/lima-${version:1}-$(uname -s)-$(uname -m).tar.gz" | sudo tar Cxzvm /usr/local
  fi
}

__docker() {
  sudo apt-get update && sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  sudo apt-get update && sudo apt-get -y install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  if ! getent group docker; then
    sudo groupadd docker
  fi

  if ! groups "${USER}" | grep docker; then
    sudo usermod -aG docker "${USER}"
  fi

  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service
}

__ensure_repo() {
  src=$1
  dest=$2

  echo "setting up ${src}"
  if [[ ! -d "${dest}" ]]; then
    git clone "${src}" "${dest}"
  else
    pushd "${dest}" > /dev/null
      git pull -r
    popd > /dev/null
  fi
}

main() {
  if docker info > /dev/null; then
    docker run --pull always --rm -v "${SCRIPT_DIR}:/mnt:ro" -w /mnt koalaman/shellcheck:stable install.sh
  fi

  setup_dependencies
  setup_dotfiles
  setup_colors
  setup_vim
}

main
