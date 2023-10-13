#!/usr/bin/env bash

set -eu -o pipefail

TMP_DIR="$(mktemp -d)"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
GITHUB_CURL_HEADERS=(--header "Accept: application/vnd.github+json")

if [[ ${GITHUB_API_TOKEN:+1} ]]; then
  GITHUB_CURL_HEADERS+=(--header "Authorization: Bearer ${GITHUB_API_TOKEN}")
fi

__ensure_repo() {
  local src dest branch
  src="${1}"
  shift
  dest="${1}"
  shift
  branch="${1:-}"
  shift || true

  if [[ "${branch}" == "latest" ]]; then
    branch="$(__latest_tag "$(echo "${src}" | awk -F/ '{printf "%s/%s",$4,$5}')")"
  fi

  echo "setting up ${src}"
  if [[ ! -d "${dest}" ]]; then

    local flags=(--depth=1)
    if [[ -n "${branch}" ]]; then
      flags+=("--branch=${branch}" --single-branch)
    fi
    git clone "${flags[@]}" "${src}" "${dest}"
  else
    pushd "${dest}" >/dev/null
    {
      if [[ -n "${branch}" ]]; then
        git fetch --all --tags
        git checkout "${branch}"
      else
        git reset --hard
        git pull -r
      fi
    }
    popd >/dev/null
  fi
}

__latest_tag() {
  local repo
  repo="${1}"
  shift

  curl -fsSLq "https://api.github.com/repos/${repo}/releases" \
    | jq -r '.[] | select(.draft == false and .prerelease == false) | .tag_name' \
    | head -n 1
}

__nvim() {
  echo "installing nvim..."
  local latest
  latest="$(__latest_tag "neovim/neovim")"

  if ! command -v nvim >/dev/null || ! grep --silent "$(nvim --version | head -n 1 | awk '{print $2}')" <(echo "${latest}"); then
    mkdir -p "${TMP_DIR}/nvim"

    pushd "${TMP_DIR}/nvim" >/dev/null
    {
      curl --fail -#qL "https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz" \
        | tar zxv --strip-components=1 --no-same-owner

      make CMAKE_BUILD_TYPE=Release
      sudo make install
    }
    popd >/dev/null
  fi

  python -m pip install --upgrade --user pynvim

  cargo install --locked tree-sitter-cli
}

__tmux() {
  echo "installing tmux..."
  local latest_version
  latest_version="$(__latest_tag "tmux/tmux")"

  if ! command -v tmux >/dev/null || ! grep --silent "${latest_version}" <(tmux -V); then
    echo "installing tmux ${latest_version}"

    curl --fail -#qL "https://github.com/tmux/tmux/releases/download/${latest_version}/tmux-${latest_version}.tar.gz" | tar --no-same-owner -zxv -C "${TMP_DIR}/"
    pushd "${TMP_DIR}/tmux-${latest_version}"
    {
      ./configure
      make -j
      sudo make install
    }
    popd
  fi
}

__go() {
  echo "installing go..."
  local version
  version="$(curl --fail -sq "https://go.dev/VERSION?m=text" | head -n1)"

  if ! command -v /usr/local/bin/go >/dev/null || ! grep --silent "${version}" <(/usr/local/bin/go version); then
    echo "installing go ${version}"
    if [[ -d /usr/local/go ]]; then
      sudo rm -rfv /usr/local/go
    fi

    local arch="amd64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    curl --fail -#qL "https://dl.google.com/go/${version}.linux-${arch}.tar.gz" | sudo tar --no-same-owner -xzv -C /usr/local
  fi

  sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
  sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
}

__zsh() {
  echo "installing zsh..."
  curl --fail -#qL -o "${TMP_DIR}/zsh-latest.tar.xz" https://sourceforge.net/projects/zsh/files/latest/download

  mkdir -p "${TMP_DIR}/zsh-latest"

  pushd "${TMP_DIR}" >/dev/null
  {
    tar -xf zsh-latest.tar.xz -C zsh-latest --strip-components=1 --no-same-owner
    pushd zsh-latest >/dev/null
    {
      local version
      version="$(grep "VERSION=" Config/version.mk | cut -d"=" -f2)"

      if ! command -v /usr/local/bin/zsh >/dev/null || ! grep --silent "${version}" <(/usr/local/bin/zsh --version); then
        ./configure
        make -j
        sudo make install

        if [[ $(grep -cw "/usr/local/bin/zsh" /etc/shells) == "0" ]]; then
          echo "/usr/local/bin/zsh" | sudo tee -a /etc/shells
        fi

        chsh -s /usr/local/bin/zsh
      fi
    }
    popd >/dev/null
  }
  popd >/dev/null
}

__rust() {
  echo "installing rust..."
  if ! command -v rustup >/dev/null; then
    curl --fail --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh -s -- -y
  fi

  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"

  rustup override set stable
  rustup update stable
}

__foot() {
  echo "installing foot..."
  if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    echo "foot requires an active wayland session skipping installation..."
    return 0
  fi

  local version
  version="$(__latest_tag alacritty/alacritty)"

  version="$(curl -X 'GET' 'https://codeberg.org/api/v1/repos/dnkl/foot/releases/latest' -H 'accept: application/json' | jq -r '.tag_name')"

  if ! command -v foot >/dev/null || ! grep --silent "${version}" <(foot --version | awk '{print $3}'); then
    sudo python -m pip install --upgrade meson

    pushd "${TMP_DIR}" >/dev/null
    {
      curl --fail -#qL https://codeberg.org/dnkl/foot/archive/1.16.1.tar.gz | tar -zx -C .
      pushd foot >/dev/null
      {
        git config --global --add safe.directory "*"
        ./pgo/pgo.sh \
          full-current-session \
          . \
          build \
          --prefix=/usr/local

        ninja -C build test
        sudo ninja -C build install
      }
      popd >/dev/null
    }
    popd >/dev/null
  fi
}

__alacritty() {
  echo "installing alacritty..."
  if ! command -v Xorg; then
    echo "no xserver installed skipping installation..."
    return 0
  fi

  local version
  version="$(__latest_tag alacritty/alacritty)"

  if ! command -v alacritty >/dev/null || ! grep --silent "${version#v}" <(alacritty --version | awk '{print $2}'); then

    mkdir -p "${TMP_DIR}/alacritty"

    pushd "${TMP_DIR}" >/dev/null
    {
      curl --fail -#qL "https://github.com/alacritty/alacritty/archive/refs/tags/${version}.tar.gz" \
        | tar zxv -C alacritty --strip-components=1 --no-same-owner

      pushd alacritty >/dev/null
      {

        if pgrep --exact alacritty; then
          local answer
          read -rp "alacritty process running. quit to continue install(Y/n)? " answer 1>&2
          answer=${answer:-y}
          case ${answer:0:1} in
            y | Y)
              pkill --exact alacritty
              ;;
            *)
              echo "alacritty has not been updated"
              return 0
              ;;
          esac
        fi
        cargo build --release

        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
        sudo cp target/release/alacritty /usr/local/bin # or anywhere else in $PATH
        sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
        sudo desktop-file-install extra/linux/Alacritty.desktop
        sudo update-desktop-database

        sudo mkdir -p /usr/local/share/man/man1
        gzip -c extra/alacritty.man | sudo tee /usr/local/share/man/man1/alacritty.1.gz >/dev/null
        gzip -c extra/alacritty-msg.man | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz >/dev/null

        mkdir -p "${HOME}/.zsh_functions"
        cp extra/completions/_alacritty "${HOME}/.zsh_functions/_alacritty"
      }
      popd >/dev/null
    }
    popd >/dev/null
  fi
}

__direnv() {
  echo "installing direnv..."
  local version
  version="$(__latest_tag "direnv/direnv")"

  if ! command -v direnv >/dev/null || ! grep --silent "${version}" <(direnv --version); then
    local arch="amd64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    sudo curl --fail -#qL -o /usr/local/bin/direnv https://github.com/direnv/direnv/releases/download/${version}/direnv.linux-${arch}
    sudo chmod +x /usr/local/bin/direnv
  fi
}

__grpcurl() {
  echo "installing grpcurl..."
  local version
  version="$(__latest_tag "fullstorydev/grpcurl")"

  if ! command -v grpcurl >/dev/null || ! grep "${version}" <(grpcurl --version | awk '{print $2}'); then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    curl --fail -#qL "https://github.com/fullstorydev/grpcurl/releases/download/${version}/grpcurl_${version#v}_linux_${arch}.tar.gz" \
      | sudo tar zxv -C /usr/local/bin grpcurl --no-same-owner
  fi
}

__lazygit() {
  echo "installing lazygit..."
  local version
  version="$(__latest_tag "jesseduffield/lazygit")"

  if ! command -v lazygit >/dev/null || ! grep "${version}" <(lazygit --version | awk '{print $6}'); then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    curl --fail -#qL "https://github.com/jesseduffield/lazygit/releases/download/${version}/lazygit_${version#v}_Linux_${arch}.tar.gz" \
      | sudo tar zxv -C /usr/local/bin lazygit --no-same-owner
  fi
}

__lazydocker() {
  echo "installing lazydocker..."
  local version
  version="$(__latest_tag "jesseduffield/lazydocker")"

  if ! command -v lazydocker >/dev/null || ! grep "${version}" <(lazydocker --version | awk '{print $6}'); then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="arm64"
    fi

    curl --fail -#qL "https://github.com/jesseduffield/lazydocker/releases/download/${version}/lazydocker_${version#v}_Linux_${arch}.tar.gz" \
      | sudo tar zxv -C /usr/local/bin lazydocker --no-same-owner
  fi
}

__logiops() {
  echo "installing logiops..."

  local version
  version="$(__latest_tag "PixlOne/logiops")"

  __ensure_repo https://github.com/PixlOne/logiops "${TMP_DIR}/logiops" latest
  pushd "${TMP_DIR}/logiops" >/dev/null
  {
    git fetch --all --tags
    git checkout "${version}"
    if ! command -v logid >/dev/null || ! grep --silent "${version}" <(logid --version); then
      mkdir -p build
      pushd build >/dev/null
      {
        cmake -DCMAKE_BUILD_TYPE=Release ..
        make
        sudo make install
      }
      popd >/dev/null

      if systemctl --version; then
        sudo systemctl enable --now logid
        sudo systemctl restart logid
      fi
    fi
  }
  popd >/dev/null
}

__qemu() {
  local version
  version="$(curl -fsSLq https://download.qemu.org/ | grep -oP 'href="\Kqemu-[0-9]+\.[0-9]+\.[0-9]+\.tar\.xz' | tail -n 1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"

  if ! command -v qemu-aarch64 >/dev/null || ! grep --silent "${version}" <(qemu-aarch64 --version | head -n 1 | awk '{print $3}'); then
    mkdir -p "${TMP_DIR}/qemu"
    pushd "${TMP_DIR}/qemu" >/dev/null
    {
      curl -OL "https://download.qemu.org/qemu-${version}.tar.xz"
      tar --no-same-owner -xvJf "qemu-${version}.tar.xz"
      cd "qemu-${version}"
      ./configure \
        --enable-slirp \
        --enable-linux-user \
        --enable-curses \
        --enable-libssh \
        --enable-gtk
      make -j "$(nproc)"
      sudo make install
    }
    popd >/dev/null
  fi
}

# __colima() {
#   echo "installing colima..."
#   local version
#   version=$(curl "${GITHUB_CURL_HEADERS[@]}" -fsSLq https://api.github.com/repos/abiosoft/colima/releases/latest | jq -r .tag_name)
#
#   if ! command -v colima >/dev/null || ! grep --silent "${version}" <(colima --version); then
#     local arch="x86_64"
#     if [[ $(uname -m) != "x86_64" ]]; then
#       arch="aarch64"
#     fi
#
#     sudo curl --fail -#qL -o /usr/local/bin/colima https://github.com/abiosoft/colima/releases/download/"${version}"/colima-Linux-"${arch}"
#     sudo chmod +x /usr/local/bin/colima
#   fi
# }

# __lima() {
#   echo "installing lima..."
#   local version
#   version=$(curl "${GITHUB_CURL_HEADERS[@]}" -fsSLq https://api.github.com/repos/lima-vm/lima/releases/latest | jq -r .tag_name)
#
#   if ! command -v limactl >/dev/null || ! grep --silent "${version}" <(limactl --version); then
#     curl --fail -#qL "https://github.com/lima-vm/lima/releases/download/${version}/lima-${version:1}-linux-$(uname -m).tar.gz" \
#       | sudo tar zxv -C /usr/local --no-same-owner
#
#   fi
# }

__docker() {
  if ! command -v docker >/dev/null; then
    curl -qfsSL https://get.docker.com | bash

    if ! getent group docker; then
      sudo groupadd docker
    fi

    if ! groups "${USER}" | grep docker; then
      sudo usermod -aG docker "${USER}"
    fi

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
  fi
}

__nerd-fonts() {
  echo "installing nerd-fonts..."

  git clone --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts "${TMP_DIR}/nerd-fonts"

  pushd "${TMP_DIR}/nerd-fonts" >/dev/null
  {
    git sparse-checkout add patched-fonts/Hack
    git sparse-checkout add patched-fonts/Inconsolata
    sudo ./install.sh --clean --install-to-system-path
  }
  popd >/dev/null
}

__lua() {
  echo "installing lua..."

  local lua_version
  lua_version="$(curl -s https://www.lua.org/download.html \
    | grep -o -m 1 'Lua [0-9]\+\.[0-9]\+\.[0-9]\+' \
    | awk '{print $2}')"

  if ! command -v lua >/dev/null || ! grep --silent "${lua_version}" <(lua -v); then
    mkdir -p "${TMP_DIR}/lua"
    pushd "${TMP_DIR}/lua" >/dev/null
    {
      curl --fail -q -sSL -O "http://www.lua.org/ftp/lua-${lua_version}.tar.gz"
      tar --no-same-owner -zxf "lua-${lua_version}.tar.gz"
      pushd "lua-${lua_version}"
      {
        sudo make all install
      }
      popd
    }
    popd >/dev/null
  fi

  if ! command -v luarocks >/dev/null; then
    local luarocks_version
    luarocks_version="$(
      curl -s https://api.github.com/repos/luarocks/luarocks/tags \
        | jq -r '.[].name' \
        | grep -v -e 'rc' -e 'beta' \
        | head -n 1 \
        | cut -c 2-
    )"

    mkdir -p "${TMP_DIR}/luarocks"
    pushd "${TMP_DIR}/luarocks" >/dev/null
    {

      curl --fail -q -sSL -O https://luarocks.org/releases/luarocks-${luarocks_version}.tar.gz
      tar --no-same-owner -zxpf luarocks-${luarocks_version}.tar.gz

      pushd luarocks-${luarocks_version} >/dev/null
      {

        ./configure --with-lua=/usr/local/
        make
        sudo make install

      }
      popd >/dev/null

    }
    popd >/dev/null
  else
    sudo luarocks install luarocks
  fi
}

__sdkman() {
  echo "installing sdkman..."
  set +u
  if [[ -f ~/.sdkman/bin/sdkman-init.sh ]]; then
    source ~/.sdkman/bin/sdkman-init.sh
    sdk selfupdate force
  else
    curl -s "https://get.sdkman.io" | bash
    source ~/.sdkman/bin/sdkman-init.sh
  fi

  sdk install java 17-open
  sdk default java 17-open
  set -u
}

__rbenv() {
  echo "installing rbenv..."
  curl -qfsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
  eval "$(~/.rbenv/bin/rbenv init - bash)"
}

__ruby() {
  echo "installing ruby..."
  local latest
  latest="$(rbenv install -l | grep -v - | tail -1)"

  rbenv install -s "${latest}"
  rbenv global "${latest}"

  gem install bundler
  gem install neovim
}

__pyenv() {
  echo "installing pyenv..."
  if [ ! -d "${HOME}/.pyenv" ]; then
    curl -qfsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
  fi

  if ! command -v pyenv >/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  fi

  eval "$(pyenv init -)"
  pyenv update
}

__python() {
  echo "installing python..."
  local latest
  latest="$(pyenv latest -k 3)"

  pyenv install -s "${latest}"
  pyenv global "${latest}"

  python -m pip install --upgrade --user pip
  python -m pip install --upgrade --user setuptools
}

__n() {
  echo "installing n..."
  if ! command -v n >&/dev/null; then
    curl --fail -#qLo "${HOME}/.local/bin/n" \
      --create-dirs \
      https://raw.githubusercontent.com/tj/n/master/bin/n

    chmod +x ~/.local/bin/n
  fi
}

__node() {
  echo "installing node..."

  export PATH=~/.local/bin:$PATH
  export N_PREFIX=~/.local

  n install latest
  n install 18
  n install 16

  n latest

  npm config set cache ~/.cache/npm --global
  npm --global cache verify
  npm install -g neovim
  npm install -g markdownlint-cli2
  npm install -g markdownlint-cli2-formatter-pretty
}

__fzf() {
  echo "installing fzf.."
  __ensure_repo https://github.com/junegunn/fzf "${HOME}/.fzf" latest
  "${HOME}/.fzf/install" --bin
}

__shellcheck() {
  echo "installing shellcheck..."
  local version
  version="$(__latest_tag "koalaman/shellcheck")"

  if ! command -v shellcheck >/dev/null || ! grep --silent "${version#v}" <(shellcheck --version | head -n 2 | tail -n 1 | awk '{print $2}'); then
    local arch="x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
      arch="aarch64"
    fi

    curl --fail -#qL "https://github.com/koalaman/shellcheck/releases/download/${version}/shellcheck-${version}.linux.${arch}.tar.xz" \
      | sudo tar --strip-components=1 --no-same-owner -C /usr/local/bin -xJv "shellcheck-${version}/shellcheck"
  fi
}

setup_dependencies() {
  echo "installing dependencies..."
  case "$(uname -s)" in
    Linux)
      sudo apt update \
        && sudo apt install -y \
          autoconf \
          automake \
          bison \
          build-essential \
          bundler \
          cmake \
          curl \
          flex \
          gettext \
          git \
          git \
          jq \
          libbz2-dev \
          libconfig++-dev \
          libevent-dev \
          libffi-dev \
          libfontconfig-dev \
          libfontconfig1-dev \
          libfreetype-dev \
          libfreetype6-dev \
          libgtk-3-dev \
          libluajit-5.1-dev \
          liblzma-dev \
          libncursesw5-dev \
          libpixman-1-dev \
          libreadline-dev \
          libslirp-dev \
          libsqlite3-dev \
          libssh-dev \
          libssl-dev \
          libtool-bin \
          libudev-dev \
          libutempter-dev \
          libutf8proc-dev \
          libwayland-dev \
          libxcb-xfixes0-dev \
          libxkbcommon-dev \
          libxml2-dev \
          libxmlsec1-dev \
          libyaml-dev \
          llvm \
          locales \
          lua5.1 \
          luajit \
          luarocks \
          ncurses-dev \
          ninja-build \
          pkg-config \
          python-is-python3 \
          python3 \
          python3-pip \
          python3-setuptools \
          python3-wheel \
          ripgrep \
          ruby-full \
          scdoc \
          tk-dev \
          unzip \
          wget \
          xclip \
          xsel \
          xz-utils \
          zip \
          zlib1g-dev

      __go
      __rust
      # __lua
      # __rbenv
      # __pyenv
      __n
      # __ruby
      # __python
      __node
      __sdkman

      __zsh
      __tmux
      __nvim
      __direnv
      __grpcurl
      __fzf
      __shellcheck
      __lazydocker
      __lazygit

      __nerd-fonts

      if command -v Xorg &>/dev/null; then
        __logiops
        __alacritty
        __foot
      fi

      if ! command -v docker &>/dev/null; then
        __docker
      fi

      # __qemu
      # __colima
      # __lima

      cargo install --locked bat
      cargo install --locked fd-find
      cargo install --locked zoxide

      ;;
    Darwin)
      if ! command -v brew >/dev/null; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl --fail -q -sSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew analytics off

      brew upgrade
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
        direnv \
        grpcurl \
        reattach-to-user-namespace \
        luajit \
        lua \
        luarocks \
        \ # rbenv \
        \ # ruby-build \
        \ # pyenv \
        fzf \
        libyaml \
        wget \
        n \
        zoxide \
        coreutils \
        lazydocker \
        lazygit

      brew install homebrew/cask-fonts/font-hack-nerd-font
      brew install --cask alacritty

      __sdkman
      __rust
      __ruby
      # __python
      __node
      ;;
  esac

  if [[ ! -d ${HOME}/.oh-my-zsh ]]; then
    sh -c "$(curl --fail -q -sSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  __ensure_repo https://github.com/romkatv/powerlevel10k "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
  __ensure_repo https://github.com/zsh-users/zsh-syntax-highlighting "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  __ensure_repo https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  __ensure_repo https://github.com/zsh-users/zsh-completions "${HOME}/.oh-my-zsh/custom/plugins/zsh-completions"
}

setup_colors() {
  echo "setting up colors..."
  mkdir -p "${HOME}/.config"

  __ensure_repo https://github.com/tinted-theming/base16-shell "${HOME}/.config/base16-shell"
  __ensure_repo https://github.com/tinted-theming/base16-fzf "${HOME}/.config/base16-fzf"

  mkdir -p "${HOME}/.oh-my-zsh/custom/plugins/base16-shell"
  ln -sf "${HOME}/.config/base16-shell/base16-shell.plugin.zsh" "${HOME}/.oh-my-zsh/custom/plugins/base16-shell/base16-shell.plugin.zsh"

  if [ ! -f "${HOME}/.config/tinted-theming/base16_shell_theme" ]; then
    bash -c "shopt -s expand_aliases; source ${HOME}/.config/base16-shell/profile_helper.sh; set_theme default-dark;"
  fi
}

setup_dotfiles() {
  echo "setting up dotfiles..."
  mkdir -p "${HOME}/.config/alacritty"
  mkdir -p "${HOME}/.config/foot"

  ln -sf "${SCRIPT_DIR}/zshrc" "${HOME}/.zshrc"
  ln -sf "${SCRIPT_DIR}/p10k.zsh" "${HOME}/.p10k.zsh"
  ln -sf "${SCRIPT_DIR}/gitconfig" "${HOME}/.gitconfig"
  ln -sf "${SCRIPT_DIR}/alacritty.yml" "${HOME}/.config/alacritty/alacritty.yml"
  ln -sf "${SCRIPT_DIR}/foot.ini" "${HOME}/.config/foot/foot.ini"
  ln -sf "${SCRIPT_DIR}/ideavimrc" "${HOME}/.ideavimrc"
  ln -sf "${SCRIPT_DIR}/bin" "${HOME}/.local/bin/dotfiles"

  if [[ "$(uname -s)" == "Linux" ]]; then
    sudo ln -sf "${SCRIPT_DIR}/logid.cfg" /etc/logid.cfg
  fi
}

setup_tmux() {
  echo "setting up tmux..."

  mkdir -p "${HOME}/.tmux/plugins/"

  ln -sf "${SCRIPT_DIR}/tmux.conf" "${HOME}/.tmux.conf"
  ln -sfn "${SCRIPT_DIR}/tmux/bin" "${HOME}/.tmux/bin"

  __ensure_repo https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"

  tmux -c 'bash -e -c "~/.tmux/plugins/tpm/bin/install_plugins" '
  tmux -c 'bash -e -c "~/.tmux/plugins/tpm/bin/update_plugins all"'
}

setup_nvim() {
  echo "setting up nvim..."

  ln -sfn "${SCRIPT_DIR}/nvim" "${HOME}/.config/nvim"
  ln -sfn "${HOME}/.config/nvim/lua/zankich/settings.lua.template" "${HOME}/.config/nvim/lua/zankich/settings.lua"

  if [[ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]]; then
    curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" \
      --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  mkdir -p "${HOME}/.local/share/nvim/zankich"
  pushd "${HOME}/.local/share/nvim/zankich" &>/dev/null
  {
    __ensure_repo https://github.com/zankich/cucumber-language-service cucumber-language-service
    pushd cucumber-language-service &>/dev/null
    {
      n exec 16 npm install
      n exec 16 npm run build
    }
    popd &>/dev/null

    __ensure_repo https://github.com/zankich/cucumber-language-server cucumber-language-server
    pushd cucumber-language-server &>/dev/null
    {
      n exec 16 npm install
      n exec 16 npm install ../cucumber-language-service
      n exec 16 npm run build
    }
    popd &>/dev/null

    __ensure_repo https://github.com/microsoft/java-debug java-debug latest
    pushd java-debug &>/dev/null
    {
      ./mvnw clean install
    }
    popd &>/dev/null

    __ensure_repo https://github.com/microsoft/vscode-java-test vscode-java-test
    pushd vscode-java-test &>/dev/null
    {
      npm install
      npm run build-plugin
    }
    popd &>/dev/null
  }
  popd &>/dev/null

  set +e
  nvim -u "${SCRIPT_DIR}/nvim/vimrc" --headless +PlugInstall +qall
  nvim -u "${SCRIPT_DIR}/nvim/vimrc" --headless +PlugUpdate +qall
  nvim -u "${SCRIPT_DIR}/nvim/vimrc" --headless +PlugUpgrade +qall
  echo
  set -e
}

main() {
  setup_dependencies
  setup_dotfiles
  setup_colors
  setup_nvim
  setup_tmux
}

main
