#!/bin/bash
# Lancer hyprpaper
hyprpaper &
sleep 1

# Forcer le chargement du wallpaper
hyprctl hyprpaper wallpaper "eDP-1,/home/omnimessie/wallpaper/default.jpg"
