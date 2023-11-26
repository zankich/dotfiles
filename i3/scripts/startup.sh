#!/usr/bin/env bash

set -x

"${HOME}/.screenlayout/dual.sh" && sleep 0.1
# needs a bit of a delay so that the screen has time to set the proper resolution
hsetroot -solid teal

pgrep parcellite | xargs -n1 kill
while pgrep parcellite; do sleep 0.1; done

parcellite &>>/tmp/parcellite.log &
disown

pgrep redshift-gtk | xargs -n1 kill
while pgrep redshift-gtk; do sleep 0.1; done

redshift -xP
redshift-gtk -t 6500k:4000k &>>/tmp/redshift.log &

disown

"${HOME}/.local/bin/dotfiles/set-x-env.sh"
"${HOME}/.config/picom/start.sh"
"${HOME}/.config/polybar/launch.sh"

exit 0
