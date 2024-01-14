#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
# polybar-msg cmd quit &>/dev/null

pgrep polybar | xargs -n1 kill 9 &>/dev/null
pgrep -f 'bash /home/azankich/.local/bin/dotfiles/stats.sh' | xargs -n1 kill 9 &>/dev/null

sleep 0.3

num=0
for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar --reload "monitor${num}" &>>/tmp/polybar-${num}.log &
  disown
  ((++num))
  sleep 0.1
done

# terminate the monitoring scripts
pgrep -f 'bash /home/azankich/.local/bin/dotfiles/stats.sh' | xargs -n1 kill 9 &>/dev/null
