#!/bin/bash
# ⚙️ ENHANCED MECHANICUS WLOGOUT LAUNCHER ⚙️

# Citations dynamiques selon l'heure
get_time_quote() {
    local hour=$(date +%H)
    if [ $hour -ge 6 ] && [ $hour -lt 12 ]; then
        echo "Morning protocols: The Forge awakens"
    elif [ $hour -ge 12 ] && [ $hour -lt 18 ]; then
        echo "Peak efficiency: Sacred work continues"  
    elif [ $hour -ge 18 ] && [ $hour -lt 22 ]; then
        echo "Evening archive: Data compilation phase"
    else
        echo "Night vigil: The Machine Spirit rests"
    fi
}

# Infos système
UPTIME=$(uptime -p | sed 's/up //' | sed 's/ hours*/h/' | sed 's/ minutes*/m/')
LOAD=$(cat /proc/loadavg | cut -d' ' -f1)
TEMP=$(sensors 2>/dev/null | grep -i core | head -1 | grep -o '[0-9]*°C' | head -1 || echo "Optimal")
QUOTE=$(get_time_quote)

# Notification système avant wlogout
notify-send -i computer -t 4000 "⚙️ Adeptus Mechanicus Power Control" \
"🕐 Machine Runtime: $UPTIME
📊 Cogitator Load: $LOAD
🌡️ Core Temperature: $TEMP
💭 Status: $QUOTE

Awaiting sacred power ritual selection..."

# Attendre un peu que la notification s'affiche
sleep 0.5

# Lancer wlogout avec style
wlogout
