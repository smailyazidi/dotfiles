#!/bin/bash

# ===== Helper Functions =====

# Check if Bluetooth power is on
power_on() {
  bluetoothctl show | grep -q "Powered: yes"
}

# ===== Main Menu =====

main_menu() {
  clear
  echo "===== System Control ====="
  echo "1) Manage Wi-Fi"
  echo "2) Manage Bluetooth"
  echo "3) Audio Control"
  echo "4) Power Options"
  echo "5) Exit"
  echo -n "Choose a number: "
  read choice

  case $choice in
  1) wifi_menu ;;
  2) bluetooth_menu ;;
  3) sound_menu ;;
  4) power_menu ;;
  5) exit ;;
  *)
    echo "Invalid option"
    sleep 1
    main_menu
    ;;
  esac
}

# ===== Wi-Fi Menu =====

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
      echo "3) Back to Main Menu"
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
      3)
        main_menu
        return
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

# ===== Bluetooth Menu =====

bluetooth_menu() {
  while true; do
    clear
    echo "===== Bluetooth Control ====="

    if power_on; then
      echo "Bluetooth Status: ON"
      bluetooth_on=true
    else
      echo "Bluetooth Status: OFF"
      bluetooth_on=false
    fi

    echo "1) Power ON/OFF Bluetooth"
    echo "2) Scan and Connect to Devices"
    echo "3) Disconnect Current Device"
    echo "4) Back to Main Menu"
    echo -n "Choose: "
    read choice

    case $choice in
    1)
      if $bluetooth_on; then
        bluetoothctl power off
        echo "Bluetooth turned OFF."
      else
        bluetoothctl power on
        echo "Bluetooth turned ON."
      fi
      sleep 1
      ;;

    2)
      if ! power_on; then
        echo "Bluetooth is OFF. Turning it ON..."
        bluetoothctl power on
        sleep 2
      fi

      echo "Scanning for devices..."
      bluetoothctl scan on &>/dev/null
      sleep 5
      bluetoothctl scan off &>/dev/null
      echo "===== Available Bluetooth Devices ====="
      mapfile -t device_lines < <(bluetoothctl devices | grep "Device")
      if [ ${#device_lines[@]} -eq 0 ]; then
        echo "No devices found."
        echo "Press Enter to return."
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

      for i in "${!names[@]}"; do
        echo "$((i + 1))) ${names[$i]} (${macs[$i]})"
      done

      echo -n "Choose a number to connect: "
      read dev_choice
      index=$((dev_choice - 1))

      if [ -z "${macs[$index]}" ]; then
        echo "Invalid choice."
        sleep 1
        continue
      fi

      device_mac="${macs[$index]}"
      device_name="${names[$index]}"
      echo "Pairing with $device_name..."
      bluetoothctl pair "$device_mac"
      sleep 2

      echo "Connecting to $device_name..."
      bluetoothctl connect "$device_mac"
      sleep 2

      if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
        echo "Connected to $device_name."
      else
        echo "Failed to connect."
      fi

      echo "Press Enter to continue."
      read
      ;;

    3)
      connected_mac=$(bluetoothctl info | grep "Device" | awk '{print $2}')
      if [ -z "$connected_mac" ]; then
        echo "No connected device."
      else
        bluetoothctl disconnect "$connected_mac"
        echo "Disconnected from $connected_mac."
      fi
      sleep 2
      ;;

    4)
      main_menu
      return
      ;;

    *)
      echo "Invalid option."
      sleep 1
      ;;
    esac
  done
}

# ===== Audio Control Menu =====

sound_menu() {
  while true; do
    clear
    echo "===== Audio Control ====="
    echo "1) Volume Up"
    echo "2) Volume Down"
    echo "3) Toggle Mute"
    echo "4) Back to Main Menu"
    echo -n "Choose: "
    read s_choice

    case $s_choice in
    1) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    2) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    3) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    4)
      main_menu
      return
      ;;
    *)
      echo "Invalid option"
      sleep 1
      ;;
    esac
  done
}

# ===== Power Menu =====

power_menu() {
  clear
  echo "===== Power Options ====="
  echo "1) Logout from Hyprland"
  echo "2) Reboot"
  echo "3) Shutdown"
  echo "4) Lock Screen"
  echo "5) Back"
  echo -n "Choose: "
  read p_choice

  case $p_choice in
  1) hyprctl dispatch exit ;;
  2) reboot ;;
  3) shutdown now ;;
  4) loginctl lock-session ;;
  5)
    main_menu
    return
    ;;
  *)
    echo "Invalid option"
    sleep 1
    power_menu
    ;;
  esac
}

# ===== Start Script =====
main_menu
