#!/usr/bin/env bash

set -x

"${HOME}/.local/bin/dotfiles/set-x-env.sh"

"${HOME}/.config/picom/start.sh"
"${HOME}/.config/polybar/launch.sh"

"${HOME}/.screenlayout/dual.sh"
# needs a bit of a delay so that the screen has time to set the proper resolution
sleep 1 && hsetroot -solid lightblue

parcellite
