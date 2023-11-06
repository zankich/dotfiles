#!/bin/sh

~/.local/bin/dotfiles/set-x-env.sh

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

mkdir -p /tmp/google-chrome
mkdir -p /tmp/mozilla

exec i3
