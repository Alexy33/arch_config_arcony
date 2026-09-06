#!/bin/bash
# ⚙️ MECHANICUS POWER INTERFACE ⚙️

# Citations Mechanicus
QUOTES=(
    "The Omnissiah guides our shutdown"
    "Flesh is weak, steel endures" 
    "Knowledge is power, guard it well"
    "The Machine Spirit watches over us"
    "Binary hymns soothe the processes"
)

QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
UPTIME=$(uptime -p | sed 's/up //')

# Afficher les infos système
notify-send -t 3000 "⚙️ Adeptus Mechanicus Interface" \
"🕐 Uptime: $UPTIME
💭 \"$QUOTE\"
📊 System: All protocols operational"
