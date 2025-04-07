#!/bin/bash

generate_gradient() {
  local start_echo=$1
  local end_echo=$2
  local steps=$3
  local index=$4
  local char="$5"

  local start_r=$(((start_echo & 0xFF0000) >> 16))
  local start_g=$(((start_echo & 0x00FF00) >> 8))
  local start_b=$((start_echo & 0x0000FF))
  local end_r=$(((end_echo & 0xFF0000) >> 16))
  local end_g=$(((end_echo & 0x00FF00) >> 8))
  local end_b=$((end_echo & 0x0000FF))

  local r=$((start_r + (end_r - start_r) * index / steps))
  local g=$((start_g + (end_g - start_g) * index / steps))
  local b=$((start_b + (end_b - start_b) * index / steps))

  printf "\033[38;2;%d;%d;%dm%s\033[0m" $r $g $b "$char"
}

ascii="░▒▓███████▓▒░░▒▓█▓▒░░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░        ░▒▓███████▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░       ░▒▓██████▓▒░░▒▓███████▓▒░ ░▒▓██████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░             ░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░     
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░             ░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░     
░▒▓███████▓▒░░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░      ░▒▓███████▓▒░░▒▓█▓▒░         ░▒▓█▓▒░     
                                                                                                                       "

start_color="0xef09f7"
end_color="0x7809f7"

while IFS= read -r line; do
  line_length=${#line}

  for ((i = 0; i < line_length; i++)); do
    char="${line:i:1}"
    generate_gradient $start_color $end_color $line_length $i "$char"
  done

  echo
done <<<"$ascii"

RESET='\033[0m'
CYAN='\033[38;2;65;113;181m'
MAGENTA='\033[38;2;133;65;181m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

#NETWORK_RANGE="192.168.1.0/24"
SCAN_INTERVAL=10 # change these if you want lol
NMAP_TIMEOUT=30

get_nterface() {
  local interface=$(ip -o -4 addr show up | awk '{if ($2 != "lo") print $2}' | head -n 1)

  if [ -z "$interface" ]; then
    echo "No interface connected to the network."
    return 1
  fi

  echo "$interface"
}

get_range() {
  local interface=$1
  if [ -z "$interface" ]; then
    echo "Usage: get_ip_range <interface>"
    return 1
  fi

  local ip_and_netmask=$(ip addr show "$interface" | grep -oP 'inet \K[\d.]+/\d+')

  if [ -z "$ip_and_netmask" ]; then
    echo "Unable to get IP and netmask for interface $interface"
    return 1
  fi

  local ip_address=$(echo "$ip_and_netmask" | cut -d '/' -f 1)
  local netmask=$(echo "$ip_and_netmask" | cut -d '/' -f 2)

  echo "$ip_address/$netmask"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -i | --interface)
    INTERFACE="$2"
    shift 2
    ;;
  *)
    shift
    ;;
  esac
done

if ! [[ -n "$INTERFACE" ]]; then
  INTERFACE=$(get_nterface)
fi

NETWORK_RANGE=$(get_range $INTERFACE)

echo "range is '$NETWORK_RANGE' and interface is $INTERFACE"

scan_network() {
  sudo timeout "$NMAP_TIMEOUT" nmap -sn -e "$INTERFACE" "$NETWORK_RANGE" 2>/dev/null |
    awk '
      /^Nmap scan report for/ {
        ip = $NF
      }
      /MAC Address:/ {
        mac = $3
        sub(/^[ \t]+/, "", $0)
        vendor = substr($0, index($0,$4))
        print mac "\t" vendor
        mac = ""
      }
    '
}

build_mapping() {
  declare -n mapping=$1
  mapping=()
  while IFS=$'\t' read -r mac vendor; do
    mapping["$mac"]="$vendor"
  done <<<"$(scan_network)"
}

declare -A prev_mapping

echo -e "${BLUE}Performing initial network scan on interface $INTERFACE...${RESET}"
build_mapping prev_mapping

if [ ${#prev_mapping[@]} -eq 0 ]; then
  echo -e "${RED}No devices found. Ensure nmap is installed and you're scanning the correct subnet.${RESET}"
  exit 1
fi

echo -e "${GREEN}Initial devices detected:${RESET}"
echo -e "  - MAC            |  󱌢 - Vendor"
echo "=========================================="
for mac in "${!prev_mapping[@]}"; do
  echo -e "${CYAN} $mac${RESET}  | ${MAGENTA} ${prev_mapping[$mac]}${RESET}"
done

echo -e "[${YELLOW}󰅛${RESET}] ${YELLOW}Monitoring for disconnected devices...${RESET}\n"

while true; do
  sleep "$SCAN_INTERVAL"
  declare -A current_mapping
  build_mapping current_mapping

  disconnected_found=false
  for mac in "${!prev_mapping[@]}"; do
    if [[ -z "${current_mapping[$mac]}" ]]; then
      echo -e "[${RED}${RESET}] Device disconnected: ${CYAN}MAC: $mac${RESET} - ${MAGENTA}Vendor: ${prev_mapping[$mac]}${RESET}"
      disconnected_found=true
    fi
  done
  prev_mapping=()
  for mac in "${!current_mapping[@]}"; do
    prev_mapping["$mac"]="${current_mapping[$mac]}"
  done
done
