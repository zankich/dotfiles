#!/usr/bin/env bash

set -eu -o pipefail

get_io_stats() {
  local sample io read write root_mount

  root_mount="$(df / | tail -n1 | awk '{print $1}')"
  sample="$(iostat -o JSON -p "${root_mount}" -y 1 1)"
  io=$(jq '.. | objects | select(has("disk_device"))' <<<"${sample}")

  read=$(jq -r '.kB_read' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")
  write=$(jq -r '.kB_wrtn' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")

  echo "${read} ${write}"
}

get_cpu_stats() {
  local sample cpu_idle usage cores freq

  sample="$(iostat -o JSON -y 1 1)"
  cpu_idle=$(jq '.. | objects | select(has("idle")) | .idle' <<<"${sample}")

  usage="$(printf "%.2f" "$(echo "scale=4; 100-${cpu_idle}" | bc -l)")"
  # freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -hur | head -n1 | xargs -I{} -n 1 echo "scale=2;{} / 1000000.0" | bc | xargs -I{} echo "{}GHz")
  # cores=$(grep siblings /proc/cpuinfo | awk '{print $3}' | head -n1)
  freq=$(grep MHz /proc/cpuinfo | awk '{print $4}' | sort -hr | head -n1 | xargs -I{} echo "scale=2;{} / 1000" | bc | xargs -I{} echo "{}GHz")
  # freq=$(grep MHz /proc/cpuinfo | awk '{print $4}' | paste -sd+ - | bc | xargs -I{} echo "{}/${cores}" | bc | xargs -I{} echo "scale=2;{} / 1000" | bc | xargs -I{} echo "{}GHz")

  echo "${usage}% ${freq}"
}

get_gpu-utilization_stats() {
  nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}'
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

  echo "${tx_speed} ${rx_speed}"
}

get_vpn_stats() {
  local status
  if ip a show tun0 up &>/dev/null; then
    # if [[ $(resolvectl dns tun0 | wc -w) == "3" ]]; then
    if ! grep "netflix.com" /etc/resolv.conf &>/dev/null; then
      status="unknown"
    else
      status="up"
    fi
  else
    status="down"
  fi

  echo "${status}"
}

get_container_stats() {
  if containers="$(timeout 1 docker ps -q | wc -l | xargs)"; then
    echo "${containers}"
  fi
}

main() {
  local stat
  stat="${1}"

  while true; do
    "get_${stat}_stats"
    case "${stat}" in
      containers)
        sleep 10
        ;;
      *)
        sleep 1
        ;;
    esac
  done
}

main "${@}"
