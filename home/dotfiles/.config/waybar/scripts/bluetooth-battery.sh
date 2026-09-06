#!/bin/bash

# Method 1: bluetoothctl
battery_level=$(bluetoothctl info 2>/dev/null | grep "Battery Percentage" | awk '{print $4}' | tr -d '()%' | head -1)

# Method 2: upower (fallback)
if [ -z "$battery_level" ] || [ "$battery_level" -eq 0 ]; then
    battery_level=$(upower -i /org/freedesktop/UPower/devices/headset_* 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%' | head -1)
fi

# Method 3: Check /sys (another fallback)
if [ -z "$battery_level" ] || [ "$battery_level" -eq 0 ]; then
    for device in /sys/class/power_supply/hid-*; do
        if [ -f "$device/capacity" ]; then
            battery_level=$(cat "$device/capacity" 2>/dev/null)
            break
        fi
    done
fi

if [ -n "$battery_level" ] && [ "$battery_level" -gt 0 ]; then
    echo "{\"text\": \"🔋$battery_level%\", \"tooltip\": \"Bluetooth Battery: $battery_level%\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"No bluetooth battery info\"}"
fi