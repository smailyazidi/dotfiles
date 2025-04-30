#!/bin/bash

# Set your network interface (e.g., use ip link to find yours)
INTERFACE="wlp2s0"

RX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

sleep 1

RX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

RX_RATE=$((($RX_NEXT - $RX_PREV) / 1024))
TX_RATE=$((($TX_NEXT - $TX_PREV) / 1024))

echo " ${RX_RATE}KB/s  ${TX_RATE}KB/s"
