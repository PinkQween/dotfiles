#!/bin/bash

# Check rfkill status for WiFi (airplane mode = both wifi and bluetooth disabled)
WIFI_BLOCKED=$(rfkill list | grep -A1 "0: ideapad_wlan" | grep -c "Soft blocked: yes")
BT_BLOCKED=$(rfkill list | grep -A1 "1: ideapad_bluetooth" | grep -c "Soft blocked: yes")

# If both are blocked, it's airplane mode
if [ "$WIFI_BLOCKED" -eq 1 ] && [ "$BT_BLOCKED" -eq 1 ]; then
  echo "󰗕 Airplane Mode"
  exit 0
fi

# Check if connected to WiFi
SSID=$(iwctl station wlan0 show 2>/dev/null | grep "Connected network" | awk '{$1=$2=""; print $0}' | xargs)

if [ -n "$SSID" ]; then
  echo "󰤨  $SSID"
else
  echo "󰌙  Offline"
fi

