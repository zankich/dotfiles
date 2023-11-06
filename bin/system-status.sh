#!/usr/bin/env bash

set -u -o pipefail

get_network_speed() {
  local interface rx_sample1 rx_sample2 tx_sample1 tx_sample2 rx_speed tx_speed
  interface="$(route | awk '/^default/{print $NF}')"

  rx_sample1="$(cat "/sys/class/net/${interface}/statistics/rx_bytes")"
  tx_sample1="$(cat "/sys/class/net/${interface}/statistics/tx_bytes")"

  sleep 1

  rx_sample2="$(cat "/sys/class/net/${interface}/statistics/rx_bytes")"
  tx_sample2="$(cat "/sys/class/net/${interface}/statistics/tx_bytes")"

  rx_speed=$(echo "scale=2; ($rx_sample2 - $rx_sample1) * 8" | bc | numfmt --round nearest --suffix "bps" --from si --to si --format="%4f")
  tx_speed=$(echo "scale=2; ($tx_sample2 - $tx_sample1) * 8" | bc | numfmt --round nearest --suffix "bps" --from si --to si --format="%4f")

  echo "nw: ↑ ${tx_speed} ↓ ${rx_speed}"
}

get_io_speed() {
  local sample io cpu_idle read write usage root_mount

  root_mount="$(df / | tail -n1 | awk '{print $1}')"
  sample="$(iostat -o JSON -p "${root_mount}" -y 1 1)"
  io=$(jq '.. | objects | select(has("disk_device"))' <<<"${sample}")
  cpu_idle=$(jq '.. | objects | select(has("idle")) | .idle' <<<"${sample}")

  read=$(jq -r '.kB_read' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")
  write=$(jq -r '.kB_wrtn' <<<"${io}" | numfmt --from-unit 1024 --round nearest --suffix "B/s" --from iec --to iec --format="%4f")
  usage="$(printf "%.2f" "$(echo "scale=4; 100-${cpu_idle}" | bc -l)")"

  freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -hur | head -n1 | xargs -I{} -n 1 echo "scale=2;{} / 1000000.0" | bc | xargs -I{} echo "{}GHz")

  echo "c: ${usage}% ${freq} | io: r ${read} w ${write}"
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

main() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    return 0
  fi

  local -a status=()
  if ip a show tun0 up &>/dev/null; then
    # if [[ $(resolvectl dns tun0 | wc -w) == "3" ]]; then
    if ! grep "netflix.com" /etc/resolv.conf &>/dev/null; then
      status+=("vpn:︕")
    else
      status+=("vpn: ")
    fi
  else
    status+=("vpn: ")
  fi

  if containers="$(timeout 1 docker ps -q | wc -l | xargs)"; then
    status+=("$(printf "%-2s" "cntrs: ${containers}")")
  fi

  status+=("m: $(free | awk '/Mem/{printf("%.2f%"), $3/$2*100}')")
  status+=("$(get_io_speed)")
  status+=("$(get_network_speed)")

  _join " | " status
}

main "${@}"
