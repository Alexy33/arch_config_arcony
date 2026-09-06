#!/bin/bash
# +++ AUSPEX OF THE COGITATOR — thermal vigil +++
# Reports the temperature of the sacred CPU as a binary state.

temp=$(sensors 2>/dev/null | grep -i 'core 0' | head -1 | awk '{print $3}' | sed 's/+//;s/\..*//;s/°C.*//')
[ -z "$temp" ] && temp=$(sensors 2>/dev/null | grep -i core | head -1 | awk '{print $3}' | sed 's/+//;s/\..*//;s/°C.*//')
[ -z "$temp" ] && temp="42"

if [ "$temp" -gt 80 ]; then
    state="overheating"
    text="🔥 OVERHEATING ${temp}°"
elif [ "$temp" -gt 60 ]; then
    state="warm"
    text="🌡 WARM ${temp}°"
else
    state="optimal"
    text="❄ OPTIMAL ${temp}°"
fi

printf '{"text":"%s","tooltip":"Cogitator core temperature: %s°C\\nThe Machine Spirit must remain cool.","class":"%s"}\n' \
    "$text" "$temp" "$state"
