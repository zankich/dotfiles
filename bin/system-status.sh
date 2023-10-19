#!/usr/bin/env bash

set -u -o pipefail

main() {
  local -a status=()
  if [[ "$(uname -s)" == "Linux" ]]; then
    if ip a show tun0 up &>/dev/null; then
      if [[ $(resolvectl dns tun0 | wc -w) == "3" ]]; then
        status+=("vpn:︕")
      else
        status+=("vpn: ")
      fi
    else
      status+=("vpn: ")
    fi
  fi

  if containers="$(timeout 1 docker ps -q | wc -l | xargs)"; then
    status+=("$(printf "%-2s" "containers: ${containers}")")
  fi

  # if [[ "$(uname -s)" == "Linux" ]]; then
  #   if (($(cat /sys/devices/system/cpu/cpufreq/boost) == 1)); then
  #     freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -ur | head -1 | xargs -I{} -n 1 echo "scale=3;{} / 1000000.0" | bc | xargs -I{} echo "{}GHz")
  #     status+=("boost: on")
  #     status+=("freq: ${freq}")
  #   fi
  # fi

  status+=("$(get_io_speed)")

  _join " | " status
}

_get_io_sample() {
  local root_mount
  root_mount="$(df / | tail -n1 | awk '{print $1}')"

  jq --arg root_mount "${root_mount}" '.. | .disk?[0] | select(. != null)' <<<"$(iostat -o JSON -p "${root_mount}")"
}

get_io_speed() {
  local sample1 sample2
  sample1=$(_get_io_sample)
  sleep 1.1
  sample2=$(_get_io_sample)

  local write read
  read=$(jq -n --argjson sample2 "$sample2" --argjson sample1 "$sample1" '$sample2.kB_read - $sample1.kB_read' | numfmt --from-unit 1024 --to iec --format="%4f")
  write=$(jq -n --argjson sample2 "$sample2" --argjson sample1 "$sample1" '$sample2.kB_wrtn - $sample1.kB_wrtn' | numfmt --from-unit 1024 --to iec --format="%4f")

  echo "io: r ${read} w ${write}"
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
