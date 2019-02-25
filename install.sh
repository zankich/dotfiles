#!/bin/bash -exu

function setup_home() {
  for dotfile in $(find . -type f -iname ".*" -printf "%f\n")
  do
    ln -sf ${PWD}/${dotfile} ${HOME}/
  done
}

function setup_colors() {
  mkdir -p $HOME/.config

  pushd $HOME/.config > /dev/null
    git clone https://github.com/chriskempson/base16-shell
    git clone https://github.com/chriskempson/base16-xresources
  popd > /dev/null
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

function setup_fonts() {
  pushd /etc/fonts/conf.d > /dev/null
    sudo ln -sf ../conf.avail/11-lcdfilter-default.conf
    sudo ln -sf ../conf.avail/10-sub-pixel-rgb.conf
  popd > /dev/null
}

function setup_lockscreen() {
  sudo systemctl enable $PWD/systemd/i3lock.service
}

function setup_bin() {
  mkdir -p $HOME/bin

  for fbin in $(ls $PWD/bin/)
  do
    ln -sf ${PWD}/bin/${fbin} ${HOME}/bin/
  done
}

function main() {
  setup_home
  setup_colors
  setup_vim
  setup_i3
  setup_pulse
  setup_fonts
  setup_lockscreen
  setup_bin
}

main
