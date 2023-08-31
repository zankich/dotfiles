#!/usr/bin/env bash

set -eu -o pipefail

main() {
  local exposure
  exposure="${1}"
  shift

  v4l2-ctl -d0 -c auto_exposure=1
  v4l2-ctl -d0 -c exposure_time_absolute="${exposure}00"
  v4l2-ctl -d0 -c focus_automatic_continuous=0
}

main "${@}"
