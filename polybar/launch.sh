#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit

num=0
for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar --reload "monitor${num}" &>/tmp/polybar-${num}.log &
  ((++num))
done
