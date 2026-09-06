#!/bin/bash

# Afficher uptime et citation
UPTIME=$(uptime -p | sed 's/up //')
QUOTES=("The Omnissiah guides our shutdown" "Knowledge is power, guard it well" "The Machine Spirit watches")
QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}

# Notification avec infos système  
notify-send -t 5000 "⚙️ Adeptus Mechanicus Power Control" \
"🕐 Machine Uptime: $UPTIME
📊 Load: $(cat /proc/loadavg | cut -d' ' -f1)
💭 \"$QUOTE\"

Select your ritual below..."

# Lancer wlogout
wlogout
