#!/usr/bin/env bash

set -eu -o pipefail

main() {
  local -a status=()
  if timeout 5 metatron smoketest &>/dev/null; then
    status+=("vpn: ")
  else
    status+=("vpn: ")
  fi

  if (($(resolvectl dns tun0 | wc -w) == 5)); then
    status+=("nflx dns: ")
  else
    status+=("nflx dns: ")
  fi

  if containers="$(docker ps -q | wc -l)"; then
    status+=("containers: ${containers}")
  fi

  if (($(cat /sys/devices/system/cpu/cpufreq/boost) == 1)); then
    freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -ur | head -1 | xargs -I{} -n 1 echo "scale=3;{} / 1000000.0" | bc | xargs -I{} echo "{}GHz")
    status+=("boost: on")
    status+=("freq: ${freq}")
  fi

  _join " | " status
}

_join() {
  local -n __join_arr
  local delimiter
  delimiter="${1}"
  shift
  __join_arr="${1}"
  shift

  local joined=""
  printf -v joined "%s${delimiter}" "${__join_arr[@]}"
  printf "%s" "${joined%"${delimiter}"}"
}

main "${@}"
