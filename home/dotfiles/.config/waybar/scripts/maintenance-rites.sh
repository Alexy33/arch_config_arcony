#!/bin/bash
# +++ ALMANAC OF THE MAINTENANCE-RITES — uptime vigil +++
# How long has the Machine Spirit gone without ritual cleansing?

uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))

if [ "$uptime_days" -gt 7 ]; then
    state="required"
    text="⚠ RITES REQUIRED ${uptime_days}d"
elif [ "$uptime_days" -gt 3 ]; then
    state="blessed"
    text="✠ BLESSED ${uptime_days}d"
else
    state="sanctified"
    text="✠ SANCTIFIED ${uptime_days}d${uptime_hours}h"
fi

printf '{"text":"%s","tooltip":"Uptime: %dd %dh\\nThe Machine endures all who serve.","class":"%s"}\n' \
    "$text" "$uptime_days" "$uptime_hours" "$state"
