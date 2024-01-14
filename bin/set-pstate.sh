#!/usr/bin/env bash

set -exu -o pipefail

main() {
  local preference
  preference="${1}"
  shift

  echo "${preference}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
}

main "${@}"
