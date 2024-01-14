#!/usr/bin/env bash

set -eu -o pipefail

_STAT_DIR="/tmp/stats"
_GPU_TEMP="${_STAT_DIR}/gpu/temp"
_GPU_UTILIZATION="${_STAT_DIR}/gpu/utilization"
_CPU_TEMP="${_STAT_DIR}/cpu/temp"
_CPU_FREQ="${_STAT_DIR}/cpu/freq"
_CPU_UTILIZATION="${_STAT_DIR}/cpu/utilization"
_CONTAINERS="${_STAT_DIR}/containers/count"
_VPN="${_STAT_DIR}/vpn/status"
_IO="${_STAT_DIR}/io/speed"
_NETWORK="${_STAT_DIR}/network/speed"
_MEMORY="${_STAT_DIR}/memory/free"

mkdir -p /tmp/stats/{gpu,cpu,io,network,vpn,containers,memory}

get_value() {
  local file
  file="${1}"
  shift

  for _ in $(seq 1 5); do
    local contents
    if contents="$(cat "${file}")"; then
      if [[ -n "${contents}" ]]; then
        printf "%s\n" "${contents}"
        return
      fi
    fi

    sleep 0.5
  done
  exit 1
}

get_memory_stats() {
  local total free meminfo
  meminfo="$(cat /proc/meminfo)"
  total="$(echo "${meminfo}" | awk '/MemTotal/ {print $2}')"
  free="$(echo "${meminfo}" | awk '/MemAvailable/ {print $2}')"

  printf "%.2f%%\n" "$(echo "scale=5; ((((${free}/${total}))-1)*-100)" | bc)" | tee "${_MEMORY}"
}

get_io_stats() {
  local sample io read write root_mount

  root_mount="$(df / | tail -n1 | awk '{print $1}')"
  sample="$(iostat -o JSON -p "${root_mount}" -y 1 1)"
  io=$(jq '.. | objects | select(has("disk_device"))' <<<"${sample}")

  read=$(jq -r '.kB_read' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")
  write=$(jq -r '.kB_wrtn' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")

  printf "%7s %7s\n" "${read}" "${write}" | tee "${_IO}" &>/dev/null
}

get_cpu-usage_stats() {
  local sample cpu_idle

  sample="$(iostat -o JSON -y 1 1)"
  cpu_idle=$(jq '.. | objects | select(has("idle")) | .idle' <<<"${sample}")

  printf "%.2f\n" "$(echo "scale=4; 100-${cpu_idle}" | bc -l)" | tee "${_CPU_UTILIZATION}" &>/dev/null
}

get_cpu-freq_stats() {
  awk '/MHz/ {print $4}' /proc/cpuinfo | sort -hr | head -n1 | xargs -I{} echo "scale=2;{} / 1000" | bc | xargs -I{} printf "%sGHz" "{}" | tee "${_CPU_FREQ}" &>/dev/null
}

get_cpu-temp_stats() {
  sensors | awk '/AMD/ {gsub("+","");gsub("°","");printf $2}' | sed 's|\.0||g' | tee "${_CPU_TEMP}" &>/dev/null
}

get_gpu-usage_stats() {
  nvidia-smi -q -d UTILIZATION | awk '/Gpu/ {printf $3}' | tee "${_GPU_UTILIZATION}" >&/dev/null
}

get_gpu-temp_stats() {
  nvidia-smi -q -d TEMPERATURE | awk '/GPU Current Temp/ {printf $5}' | tee "${_GPU_TEMP}" &>/dev/null
}

get_network_stats() {
  local interface rx_sample1 rx_sample2 tx_sample1 tx_sample2 rx_speed tx_speed
  interface="$(route | awk '/^default/{print $NF}')"

  rx_sample1="$(cat "/sys/class/net/${interface}/statistics/rx_bytes")"
  tx_sample1="$(cat "/sys/class/net/${interface}/statistics/tx_bytes")"

  sleep 1

  rx_sample2="$(cat "/sys/class/net/${interface}/statistics/rx_bytes")"
  tx_sample2="$(cat "/sys/class/net/${interface}/statistics/tx_bytes")"

  rx_speed=$(echo "scale=2; ($rx_sample2 - $rx_sample1) * 8" | bc | numfmt --round nearest --suffix "bps" --from si --to si --format="%4f")
  tx_speed=$(echo "scale=2; ($tx_sample2 - $tx_sample1) * 8" | bc | numfmt --round nearest --suffix "bps" --from si --to si --format="%4f")

  printf "%7s %7s\n" "${tx_speed}" "${rx_speed}" | tee "${_NETWORK}" &>/dev/null
}

get_vpn_stats() {
  local status
  if ip a show tun0 up &>/dev/null; then
    if ! grep "netflix.com" /etc/resolv.conf &>/dev/null; then
      status="unknown"
    else
      status="up"
    fi
  else
    status="down"
  fi

  printf "%s\n" "${status}" | tee "${_VPN}" &>/dev/null
}

get_container_stats() {
  if containers="$(timeout 1 docker ps -q | wc -l | xargs)"; then
    printf "%s\n" "${containers}" | tee "${_CONTAINERS}" &>/dev/null
  else
    printf "\n"
  fi
}

loop() {
  local stat
  stat="${1}"
  shift

  while true; do
    case "${stat}" in
      containers)
        get_container_stats &
        ;;
      gpu)
        get_gpu-temp_stats &
        get_gpu-usage_stats &
        ;;
      cpu)
        get_cpu-temp_stats &
        get_cpu-usage_stats &
        get_cpu-freq_stats &
        ;;
      *)
        "get_${stat}_stats" &
        ;;
    esac

    wait

    sleep 0.3
  done
}

main() {
  local stat tail
  stat="${1:-}"
  tail="${2:-false}"

  if [[ -z "${stat}" ]]; then
    echo "running background loops"
    loop containers &
    loop network &
    loop io &
    loop vpn &
    loop gpu &
    loop cpu &
    loop memory &

    wait
  else
    while
      case "${stat}" in
        containers)
          get_value "${_CONTAINERS}"
          ;;
        network)
          get_value "${_NETWORK}"
          ;;
        io)
          get_value "${_IO}"
          ;;
        vpn)
          get_value "${_VPN}"
          ;;
        memory)
          get_value "${_MEMORY}"
          ;;
        gpu)
          printf "%2s%% %2sC\n" "$(get_value "${_GPU_UTILIZATION}")" "$(get_value "${_GPU_TEMP}")"
          ;;
        cpu)
          printf "%6s%% %7s %3s\n" "$(get_value "${_CPU_UTILIZATION}")" "$(get_value "${_CPU_FREQ}")" "$(get_value "${_CPU_TEMP}")"
          ;;
        *) ;;
      esac
    do
      "${tail}"
      sleep 0.3
    done
  fi
}

main "${@}"
