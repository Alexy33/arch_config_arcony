#!/bin/bash
# Réactive le Arc, passe en 144Hz, monte la luminosité
sudo sh -c 'echo 0000:03:00.0 > /sys/bus/pci/drivers/i915/bind' 2>/dev/null
hyprctl keyword monitor "eDP-1,1920x1080@144,auto,1"
brightnessctl set 100%
notify-send "Gaming mode" "Arc actif, 144Hz, luminosité max"
