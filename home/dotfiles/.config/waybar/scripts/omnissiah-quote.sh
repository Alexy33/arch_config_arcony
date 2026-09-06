#!/bin/bash
# +++  RITE OF THE OMNISSIAH'S WORD  +++
# Emits a sanctified prayer chosen by the holy randomizer (servitor: $RANDOM)
# Used as the rotating tooltip/text for the omnissiah waybar module.
#
# Hidden vow:
# 01001100 01001111 01000111 01001001 01000011  ::  LOGIC

QUOTES_FILE="$HOME/.config/hypr/mechanicus_quotes.txt"

if [ -f "$QUOTES_FILE" ]; then
    quote=$(shuf -n 1 "$QUOTES_FILE")
else
    # Fallback litany — recited from memory of the Magos
    fallback=(
        "Ave Omnissiah"
        "Flesh is weak, steel endures"
        "From the weakness of the mind, Omnissiah save us"
        "The Machine is eternal"
        "Knowledge is power, guard it well"
        "Code is law, logic is truth"
        "Praise the Machine God"
        "In circuits we trust"
    )
    quote="${fallback[$((RANDOM % ${#fallback[@]}))]}"
fi

# Emit JSON for waybar with the quote as both text and tooltip
text="+++ ${quote^^} +++"
tooltip="⚙  ${quote}\n\n— Cult Mechanicus, Liturgia Technis"

# Escape for JSON
text_esc=$(printf '%s' "$text" | sed 's/"/\\"/g')
tooltip_esc=$(printf '%s' "$tooltip" | sed 's/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

printf '{"text":"%s","tooltip":"%s","class":"omnissiah"}\n' "$text_esc" "$tooltip_esc"
