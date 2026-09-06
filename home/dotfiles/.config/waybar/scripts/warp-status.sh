#!/bin/bash
# +++ NOOSPHERIC AUGUR — warp travel auspex +++
# Probes the Astronomican (8.8.8.8) to gauge the stability of the Warp.

ping_result=$(ping -c 1 -W 2 8.8.8.8 2>/dev/null)
if [ $? -eq 0 ]; then
    latency=$(echo "$ping_result" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print int($1)}')
    if [ "$latency" -lt 50 ]; then
        state="stable"
        text="≋ STABLE ${latency}ms"
    elif [ "$latency" -lt 100 ]; then
        state="turbulent"
        text="≋ TURBULENT ${latency}ms"
    else
        state="chaotic"
        text="≋ CHAOTIC ${latency}ms"
    fi
    tooltip="Noospheric Latency: ${latency}ms\\nThe Astronomican guides our packets."
else
    state="severed"
    text="✘ SEVERED"
    tooltip="The Warp link is severed.\\nMachine Spirit isolated. Recite the Rite of Reconnection."
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$state"
