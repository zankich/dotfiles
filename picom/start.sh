#!/usr/bin/env bash

set -x

pgrep picom | xargs -n1 kill -9

sleep 1

DISPLAY=":0" picom -b --config "${HOME}/.config/picom/picom.conf" --log-file /tmp/picom.log
