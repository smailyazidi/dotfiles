#!/bin/bash

# === Wi-Fi Menu Script ===

wifi_menu() {
  while true; do
    clear
    echo "===== Wi-Fi Menu ====="

    wifi_status=$(nmcli radio wifi)
    echo "Wi-Fi is: $wifi_status"

    current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d ':' -f2)

    if [[ "$wifi_status" == "disabled" ]]; then
      echo "Wi-Fi is turned off."
      echo "1) Turn Wi-Fi ON"
      echo "q) Quit"
      echo -n "Choose an option: "
      read choice

      case "$choice" in
      1)
        nmcli radio wifi on && echo "✅ Wi-Fi enabled." || echo "❌ Failed to enable Wi-Fi."
        sleep 2
        ;;
      q)
        break
        ;;
      *)
        echo "❌ Invalid option."
        sleep 2
        ;;
      esac

    elif [[ -n "$current_ssid" ]]; then
      echo "Connected to: $current_ssid"
      echo "1) Turn Wi-Fi OFF"
      echo "2) Disconnect from $current_ssid"
      echo "q) Quit"
      echo -n "Choose an option: "
      read choice

      case "$choice" in
      1)
        nmcli radio wifi off && echo "✅ Wi-Fi disabled." || echo "❌ Failed to disable Wi-Fi."
        sleep 2
        ;;
      2)
        echo "Disconnecting from $current_ssid..."
        nmcli con down id "$current_ssid" && echo "✅ Disconnected." || echo "❌ Failed to disconnect."
        sleep 2
        ;;
      q)
        break
        ;;
      *)
        echo "❌ Invalid selection."
        sleep 2
        ;;
      esac

    else
      echo "Not connected to Wi-Fi."
      echo ""
      echo "Scanning for available networks..."
      mapfile -t network_list < <(nmcli -t -f SSID,SECURITY dev wifi | grep -v "^:" | sort -u)

      if [ ${#network_list[@]} -eq 0 ]; then
        echo "No networks found."
        sleep 2
        continue
      fi

      echo "===== Available Networks ====="
      for i in "${!network_list[@]}"; do
        ssid=$(echo "${network_list[$i]}" | cut -d ':' -f1)
        sec=$(echo "${network_list[$i]}" | cut -d ':' -f2)
        if [[ "$sec" == "--" || -z "$sec" ]]; then
          echo "$((i + 1))) $ssid (Open Network)"
        else
          echo "$((i + 1))) $ssid (Locked Network)"
        fi
      done
      echo "a) Turn Wi-Fi OFF"
      echo "r) Refresh"
      echo "q) Quit"
      echo -n "Choose a network or option: "
      read choice

      if [[ "$choice" == "q" ]]; then
        break
      elif [[ "$choice" == "r" ]]; then
        continue
      elif [[ "$choice" == "a" ]]; then
        nmcli radio wifi off && echo "✅ Wi-Fi disabled." || echo "❌ Failed to disable Wi-Fi."
        sleep 2
        continue
      elif ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#network_list[@]})); then
        echo "❌ Invalid selection."
        sleep 2
        continue
      fi

      selected="${network_list[$((choice - 1))]}"
      ssid=$(echo "$selected" | cut -d ':' -f1)
      sec=$(echo "$selected" | cut -d ':' -f2)

      if [[ "$sec" == "--" || -z "$sec" ]]; then
        echo "Connecting to open network: $ssid..."
        if nmcli device wifi connect "$ssid"; then
          echo "✅ Connected to $ssid"
        else
          echo "❌ Failed to connect to $ssid"
        fi
      else
        read -s -p "Enter password for $ssid: " password
        echo
        if nmcli device wifi connect "$ssid" password "$password"; then
          echo "✅ Connected to $ssid"
        else
          echo "❌ Connection failed. Wrong password?"
        fi
      fi
      sleep 2
    fi
  done
}

wifi_menu
