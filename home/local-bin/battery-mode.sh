#!/bin/bash
# Désactive le Arc, repasse en 60Hz
sudo sh -c 'echo 0000:03:00.0 > /sys/bus/pci/drivers/i915/unbind' 2>/dev/null
hyprctl keyword monitor "eDP-1,1920x1080@60,auto,1"
brightnessctl set 50%
notify-send "Battery mode" "Arc unbind, 60Hz, batterie économisée"
