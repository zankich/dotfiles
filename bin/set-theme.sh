#!/usr/bin/env bash

set -eu -o pipefail

reload_nvim() {
  pushd "${HOME}/.cache/nvim/listen" >/dev/null
  for file in *.pipe; do
    set +e
    nvim --server "${file}" --remote-send '<space>r'
    set -e
  done
  popd >/dev/null
}

set_theme() {
  local theme
  theme="${1}"
  shift

  case "${theme}" in
    dark)
      theme="base16_onedark"
      ;;
    light)

      theme="base16_equilibrium-gray-light"
      ;;
    *)
      theme="base16_${theme}"
      ;;

  esac

  tmux new-window -a "zsh -i -c '${theme};omz reload &; exit'"

  # it could take a bit of time for the theme change to take affect and reaload the shell
  sleep 1
}

main() {
  set_theme "${@}"
  reload_nvim
}

main "${@}"
