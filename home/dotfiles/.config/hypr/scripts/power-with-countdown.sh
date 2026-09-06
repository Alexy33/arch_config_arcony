#!/bin/bash
# Script power amélioré avec countdown

ACTION=$1

case $ACTION in
    "shutdown"|"reboot")
        # Countdown pour les actions critiques
        zenity --question --title="⚡ $ACTION Protocol" \
               --text="🤖 Initiate $ACTION sequence?\n\nThis will start a 5-second countdown." \
               --ok-label="Execute" --cancel-label="Cancel" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            for i in 5 4 3 2 1; do
                notify-send -t 1000 "⚡ $ACTION Protocol" "Executing in $i seconds..."
                sleep 1
            done
            ~/.config/hypr/scripts/power.sh $ACTION
        fi
        ;;
    *)
        # Autres actions directes
        ~/.config/hypr/scripts/power.sh $ACTION
        ;;
esac
