#!/bin/bash
# Simple script avec notification puis wlogout

UPTIME=$(uptime -p | sed 's/up //')
QUOTES=("The Omnissiah guides our choice" "Knowledge is power" "The Machine Spirit watches")
QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}

# Une seule notification simple
notify-send "⚙️ Power Control" "Uptime: $UPTIME\n\"$QUOTE\""

# Wlogout normal
wlogout
