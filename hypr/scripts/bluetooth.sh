#!/bin/bash

# ===== Color Definitions =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ===== Path to store last connected MAC address =====
LAST_DEVICE_FILE="$HOME/.last_bt_device"

# ===== Check if Bluetooth is Powered On =====
power_on() {
  bluetoothctl show | grep -q "Powered: yes"
}

# ===== Dummy Main Menu =====
main_menu() {
  echo -e "${CYAN}Returning to Main Menu...${RESET}"
  sleep 1
  clear
  exit 0
}

# ===== Auto-connect Function =====
auto_connect_last_device() {
  if power_on && [ -f "$LAST_DEVICE_FILE" ]; then
    last_mac=$(cat "$LAST_DEVICE_FILE")
    if bluetoothctl devices | grep -q "$last_mac"; then
      echo -e "${BLUE}Attempting auto-connect to last device: ${YELLOW}$last_mac${RESET}"
      bluetoothctl connect "$last_mac" &>/dev/null
      sleep 2
      if bluetoothctl info "$last_mac" | grep -q "Connected: yes"; then
        echo -e "${GREEN}Auto-connected to $last_mac.${RESET}"
      else
        echo -e "${RED}Failed to auto-connect to $last_mac.${RESET}"
      fi
      sleep 2
    fi
  fi
}

# ===== Bluetooth Menu =====
bluetooth_menu() {
  auto_connect_last_device # <--- Run auto-connect here, once

  while true; do
    clear
    echo -e "${BLUE}===== Bluetooth Control =====${RESET}"

    if power_on; then
      echo -e "Bluetooth Status: ${GREEN}ON${RESET}"
      bluetooth_on=true
    else
      echo -e "Bluetooth Status: ${RED}OFF${RESET}"
      bluetooth_on=false
    fi

    echo
    echo -e "${CYAN}1)${RESET} Power ${YELLOW}ON/OFF${RESET} Bluetooth"
    echo -e "${CYAN}2)${RESET} ${GREEN}Scan${RESET} and ${GREEN}Connect${RESET} to Devices"
    echo -e "${CYAN}3)${RESET} ${RED}Disconnect${RESET} Current Device"
    echo -e "${CYAN}q)${RESET} ${RED}Quit${RESET}"

    echo -ne "${YELLOW}Choose: ${RESET}"
    read choice

    case $choice in
    1)
      if $bluetooth_on; then
        bluetoothctl power off
        echo -e "${RED}Bluetooth turned OFF.${RESET}"
      else
        bluetoothctl power on
        echo -e "${GREEN}Bluetooth turned ON.${RESET}"
        auto_connect_last_device
      fi
      sleep 1
      ;;

    2)
      if ! power_on; then
        echo -e "${YELLOW}Bluetooth is OFF. Turning it ON...${RESET}"
        bluetoothctl power on
        sleep 2
      fi

      echo -e "${BLUE}Scanning for devices...${RESET}"
      bluetoothctl scan on &>/dev/null
      sleep 5
      bluetoothctl scan off &>/dev/null

      echo -e "${BLUE}===== Available Bluetooth Devices =====${RESET}"
      mapfile -t device_lines < <(bluetoothctl devices | grep "Device")
      if [ ${#device_lines[@]} -eq 0 ]; then
        echo -e "${YELLOW}No devices found.${RESET}"
        echo -e "${CYAN}Press Enter to return.${RESET}"
        read
        continue
      fi

      declare -a macs
      declare -a names

      for line in "${device_lines[@]}"; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f 3-)
        macs+=("$mac")
        names+=("$name")
      done

      echo
      for i in "${!names[@]}"; do
        echo -e "${CYAN}$((i + 1)))${RESET} ${names[$i]} ${YELLOW}(${macs[$i]})${RESET}"
      done

      echo -ne "${YELLOW}Choose a number to connect: ${RESET}"
      read dev_choice
      index=$((dev_choice - 1))

      if [ -z "${macs[$index]}" ]; then
        echo -e "${RED}Invalid choice.${RESET}"
        sleep 1
        continue
      fi

      device_mac="${macs[$index]}"
      device_name="${names[$index]}"

      echo -e "${BLUE}Pairing with ${device_name}...${RESET}"
      bluetoothctl pair "$device_mac"
      bluetoothctl trust "$device_mac" # <--- Add trust
      sleep 2

      echo -e "${BLUE}Connecting to ${device_name}...${RESET}"
      bluetoothctl connect "$device_mac"
      sleep 2

      if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
        echo "$device_mac" >"$LAST_DEVICE_FILE"
        echo -e "${GREEN}Connected to ${device_name}.${RESET}"
      else
        echo -e "${RED}Failed to connect.${RESET}"
      fi

      echo -e "${CYAN}Press Enter to continue.${RESET}"
      read
      ;;

    3)
      connected_mac=$(bluetoothctl info | grep "Device" | awk '{print $2}')
      if [ -z "$connected_mac" ]; then
        echo -e "${YELLOW}No connected device.${RESET}"
      else
        bluetoothctl disconnect "$connected_mac"
        echo -e "${GREEN}Disconnected from $connected_mac.${RESET}"
      fi
      sleep 2
      ;;
    q)
      break
      ;;
    *)
      echo -e "${RED}Invalid option.${RESET}"
      sleep 1
      ;;
    esac
  done
}

# ===== Start =====
bluetooth_menu
