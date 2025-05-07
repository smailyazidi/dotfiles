#!/bin/bash

# === Wi-Fi Menu Script with Colors ===

# Color definitions
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

wifi_menu() {
  while true; do
    clear
    echo -e "${BOLD}${BLUE}===== Wi-Fi Menu =====${RESET}"

    wifi_status=$(nmcli radio wifi)
    echo -e "${CYAN}Wi-Fi is: ${YELLOW}$wifi_status${RESET}"

    current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d ':' -f2)

    if [[ "$wifi_status" == "disabled" ]]; then
      echo -e "${RED}Wi-Fi is turned off.${RESET}"
      echo "1) Turn Wi-Fi ON"
      echo "q) Quit"
      echo -ne "${MAGENTA}Choose an option: ${RESET}"
      read choice

      case "$choice" in
      1)
        nmcli radio wifi on && echo -e "${GREEN}✅ Wi-Fi enabled.${RESET}" || echo -e "${RED}❌ Failed to enable Wi-Fi.${RESET}"
        sleep 2
        ;;
      q)
        break
        ;;
      *)
        echo -e "${RED}❌ Invalid option.${RESET}"
        sleep 2
        ;;
      esac

    elif [[ -n "$current_ssid" ]]; then
      echo -e "${GREEN}Connected to: $current_ssid${RESET}"
      echo "1) Turn Wi-Fi OFF"
      echo "2) Disconnect from $current_ssid"
      echo "q) Quit"
      echo -ne "${MAGENTA}Choose an option: ${RESET}"
      read choice

      case "$choice" in
      1)
        nmcli radio wifi off && echo -e "${GREEN}✅ Wi-Fi disabled.${RESET}" || echo -e "${RED}❌ Failed to disable Wi-Fi.${RESET}"
        sleep 2
        ;;
      2)
        echo -e "${YELLOW}Disconnecting from $current_ssid...${RESET}"
        nmcli con down id "$current_ssid" && echo -e "${GREEN}✅ Disconnected.${RESET}" || echo -e "${RED}❌ Failed to disconnect.${RESET}"
        sleep 2
        ;;
      q)
        break
        ;;
      *)
        echo -e "${RED}❌ Invalid selection.${RESET}"
        sleep 2
        ;;
      esac

    else
      echo -e "${YELLOW}Not connected to Wi-Fi.${RESET}\n"
      echo -e "${CYAN}Scanning for available networks...${RESET}"
      mapfile -t network_list < <(nmcli -t -f SSID,SECURITY dev wifi | grep -v "^:" | sort -u)

      if [ ${#network_list[@]} -eq 0 ]; then
        echo -e "${RED}No networks found.${RESET}"
        sleep 2
        continue
      fi

      echo -e "${BOLD}${BLUE}===== Available Networks =====${RESET}"
      for i in "${!network_list[@]}"; do
        ssid=$(echo "${network_list[$i]}" | cut -d ':' -f1)
        sec=$(echo "${network_list[$i]}" | cut -d ':' -f2)
        if [[ "$sec" == "--" || -z "$sec" ]]; then
          echo -e "$((i + 1))) ${GREEN}$ssid${RESET} (Open Network)"
        else
          echo -e "$((i + 1))) ${YELLOW}$ssid${RESET} (Locked Network)"
        fi
      done
      echo "a) Turn Wi-Fi OFF"
      echo "r) Refresh"
      echo "q) Quit"
      echo -ne "${MAGENTA}Choose a network or option: ${RESET}"
      read choice

      if [[ "$choice" == "q" ]]; then
        break
      elif [[ "$choice" == "r" ]]; then
        continue
      elif [[ "$choice" == "a" ]]; then
        nmcli radio wifi off && echo -e "${GREEN}✅ Wi-Fi disabled.${RESET}" || echo -e "${RED}❌ Failed to disable Wi-Fi.${RESET}"
        sleep 2
        continue
      elif ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#network_list[@]})); then
        echo -e "${RED}❌ Invalid selection.${RESET}"
        sleep 2
        continue
      fi

      selected="${network_list[$((choice - 1))]}"
      ssid=$(echo "$selected" | cut -d ':' -f1)
      sec=$(echo "$selected" | cut -d ':' -f2)

      if [[ "$sec" == "--" || -z "$sec" ]]; then
        echo -e "${YELLOW}Connecting to open network: $ssid...${RESET}"
        if nmcli device wifi connect "$ssid"; then
          echo -e "${GREEN}✅ Connected to $ssid${RESET}"
        else
          echo -e "${RED}❌ Failed to connect to $ssid${RESET}"
        fi
      else
        read -s -p "$(echo -e "${MAGENTA}Enter password for $ssid: ${RESET}")" password
        echo
        if nmcli device wifi connect "$ssid" password "$password"; then
          echo -e "${GREEN}✅ Connected to $ssid${RESET}"
        else
          echo -e "${RED}❌ Connection failed. Wrong password?${RESET}"
        fi
      fi
      sleep 2
    fi
  done
}

wifi_menu
