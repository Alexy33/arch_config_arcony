#!/bin/bash
# Custom power menu avec toutes les fonctionnalités

UPTIME=$(uptime -p | sed 's/up //')
QUOTE="The Omnissiah guides our shutdown"

choice=$(echo -e "🔒 Sacred Lock\n⚙️ Machine Rest\n💤 Deep Sleep\n🔄 Sacred Reboot (countdown)\n⚡ Final Rest (countdown)" | \
rofi -dmenu -p "⚙️ Power Control - Uptime: $UPTIME" \
     -theme ~/.config/rofi/mechanicus-current.rasi \
     -mesg "💭 $QUOTE")

case "$choice" in
    "🔒 Sacred Lock") hyprlock ;;
    "⚙️ Machine Rest") hyprctl dispatch exit 0 ;;
    "💤 Deep Sleep") systemctl suspend ;;
    "🔄 Sacred Reboot (countdown)") 
        for i in 5 4 3 2 1; do 
            notify-send -t 1000 "🔄 Sacred Reboot" "Rebooting in $i..." 
            sleep 1
        done
        systemctl reboot ;;
    "⚡ Final Rest (countdown)")
        for i in 5 4 3 2 1; do 
            notify-send -t 1000 "⚡ Final Rest" "Shutdown in $i..." 
            sleep 1
        done
        systemctl poweroff ;;
esac
