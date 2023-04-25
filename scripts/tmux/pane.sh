#!/bin/bash -eu

join-pane() {
  local window pane
  window="$(tmux list-windows -f '#{==:#{window_name},_background_panes}' -F \#{window_index})"
  if [[ -n "${window}" ]]; then
    pane="$(tmux list-panes -t "${window}" -f '#{pane_active}' -F \#{pane_index})"
    tmux join-pane -l "25%" -s "${window}.${pane}"
  fi
}

break-pane() {
  local window current
  window="$(tmux list-windows -f '#{==:#{window_name},_background_panes}' -F \#{window_index})"

  if [[ -n "${window}" ]]; then
    current="$(tmux list-windows -f '#{window_active}' -F \#{window_index})"
    tmux join-pane -t "${window}"
    tmux select-window -t "${current}"
  else
    tmux break-pane -d -n _background_panes
  fi
}

main() {
  local cmd
  cmd="${1}"
  shift

  case "${cmd}" in
    join-pane)
      join-pane
      ;;
    break-pane)
      break-pane
      ;;
    *)
      echo >&2 "Unknown sub-command"
      exit 1
      ;;
  esac
}

main "${@}"
