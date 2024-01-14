#!/usr/bin/bash

set -euo pipefail

main() {
  local action
  action="${1:-}"

  case "${action}" in
    history)
      if [[ "$(dunstctl count displayed)" != 0 ]]; then
        dunstctl close-all
      else
        for _ in $(seq 1 "$(dunstctl count history)"); do
          dunstctl history-pop
        done
      fi
      ;;
    pause)
      dunstctl set-paused toggle
      ;;
    *)
      while true; do
        if [[ "$(dunstctl is-paused)" == "true" ]]; then
          echo "🔕"
        else
          echo "🔔"
        fi

        sleep 1
      done
      ;;
  esac

  exit 0
}

main "${@}"
