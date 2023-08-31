#!/usr/bin/env bash

set -eu -o pipefail

reload_nvim() {
  pushd $HOME/.cache/nvim/listen >/dev/null
  for file in *.pipe; do
    nvim --server "${file}" --remote-send '<space>r'
  done
  popd >/dev/null
}

set_theme() {
  local theme
  theme="${1}"
  shift

  if [[ "${theme}" == "dark" ]]; then
    theme="base16_onedark"
  else
    theme="base16_equilibrium-gray-light"
  fi

  tmux new-window -a "zsh -i -c '${theme};omz reload &;exit'"
}

main() {
  set_theme "${@}"
  reload_nvim
}

main "${@}"
