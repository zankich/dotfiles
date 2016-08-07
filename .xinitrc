#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

if [ -s ~/.Xmodmap ]; then
    xmodmap ~/.Xmodmap
fi

[[ -f ~/.Xresources ]] && xrdb -merge -load ~/.Xresources

autocutsel -fork
autocutsel -selection PRIMARY -fork

# set key delay
xset r rate 200 30

# set custom keys
xbindkeys

exec i3
