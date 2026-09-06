#!/bin/bash
# +++ DIVINATION OF THE MACHINE SPIRIT — load auspex +++
# Senses the agitation of the local Machine Spirit via system load.

load=$(awk '{print int($1*100)}' /proc/loadavg)
loadavg=$(awk '{print $1}' /proc/loadavg)

if [ "$load" -gt 200 ]; then
    state="agitated"
    text="⚙ AGITATED"
elif [ "$load" -gt 100 ]; then
    state="active"
    text="⚙ ACTIVE"
else
    state="peaceful"
    text="⚙ PEACEFUL"
fi

printf '{"text":"%s","tooltip":"Machine Spirit load: %s\\nPerform the Litany of Calmness if agitated.","class":"%s"}\n' \
    "$text" "$loadavg" "$state"
