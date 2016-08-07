#!/bin/bash -exu

function setup_home() {
  for dotfile in $(find . -type f -iname ".*" -printf "%f\n")
  do
    ln -sf ${PWD}/${dotfile} ${HOME}/
  done
}

function setup_vim() {
  mkdir -p $HOME/.config
  mkdir -p $HOME/.vim

  ln -sf $HOME/.vim $HOME/.config/nvim
  ln -sf $HOME/.vimrc $HOME/.config/nvim/init.vim
}

function setup_i3() {
  mkdir -p $HOME/.config/i3

  ln -sf $PWD/i3/config $HOME/.config/i3/
  ln -sf $PWD/i3/status.conf $HOME/.config/i3/
}

function setup_pulse() {
  mkdir -p $HOME/.config/pulse

  ln -sf $PWD/pulse/daemon.conf $HOME/.config/pulse/
}

function main() {
  setup_home
  setup_vim
  setup_i3
  setup_pulse
}

main
