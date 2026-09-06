#!/bin/bash
# ⚙️ MECHANICUS POWER MENU WITH ZENITY ⚙️

# Citations et infos système
QUOTES=(
    "The Omnissiah guides our shutdown"
    "Flesh is weak, steel endures"
    "Knowledge is power, guard it well"
    "The Machine Spirit watches over us"
    "Binary hymns soothe the processes"
)

QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cat /proc/loadavg | cut -d' ' -f1)
TEMP=$(sensors 2>/dev/null | grep -i temp | head -1 | grep -o '[0-9]*°C' | head -1 || echo "N/A")

# Menu principal avec infos système
choice=$(zenity --list \
    --title="⚙️ Adeptus Mechanicus Power Control" \
    --text="🖥️ Machine Status: All Forge protocols operational
⏱️ Uptime: $UPTIME | 📊 Load: $LOAD | 🌡️ Temp: $TEMP
💭 Omnissiah's Wisdom: \"$QUOTE\"

Select your sacred ritual:" \
    --column="Icon" --column="Action" --column="Description" \
    --width=600 --height=400 \
    "🔒" "Sacred Lock" "Engage security protocols" \
    "⚙️" "Machine Rest" "Logout from current session" \
    "💤" "Deep Sleep" "Suspend system operations" \
    "🔄" "Sacred Reboot" "Restart with 5s countdown" \
    "⚡" "Final Rest" "Shutdown with 5s countdown" \
    "📊" "System Info" "View detailed diagnostics" \
    "❌" "Cancel" "Abort ritual")

case "$choice" in
    "Sacred Lock")
        zenity --info --title="🔒 Sacred Lock" --text="Engaging Omnissiah security protocols..." --timeout=2
        hyprlock
        ;;
    "Machine Rest")
        if zenity --question --title="⚙️ Machine Rest" --text="Logout from current forge session?"; then
            hyprctl dispatch exit 0
        fi
        ;;
    "Deep Sleep")
        zenity --info --title="💤 Deep Sleep" --text="Initiating hibernation protocols..." --timeout=2
        systemctl suspend
        ;;
    "Sacred Reboot")
        if zenity --question --title="🔄 Sacred Reboot" --text="This will restart the machine with a 5-second countdown.\n\nProceed with sacred reboot ritual?"; then
            countdown_and_execute "reboot" "🔄 Sacred Reboot"
        fi
        ;;
    "Final Rest")
        if zenity --question --title="⚡ Final Rest" --text="This will shutdown the machine with a 5-second countdown.\n\n⚠️ Proceed with final rest ritual?"; then
            countdown_and_execute "shutdown" "⚡ Final Rest"
        fi
        ;;
    "System Info")
        show_system_info
        ;;
    *)
        zenity --info --title="🤖 Ritual Cancelled" --text="Power control ritual aborted by user." --timeout=2
        ;;
esac

# Fonction countdown avec zenity
countdown_and_execute() {
    local action=$1
    local title=$2
    
    # Countdown avec progress bar
    (
    for i in {1..5}; do
        echo $((i * 20))
        echo "# $title in $((6-i)) seconds... (Close this window to cancel)"
        sleep 1
    done
    echo 100
    echo "# Executing $title..."
    ) | zenity --progress --title="$title" --text="Countdown in progress..." --percentage=0 --auto-close
    
    # Si l'utilisateur n'a pas fermé la fenêtre
    if [ $? -eq 0 ]; then
        case $action in
            "reboot") systemctl reboot ;;
            "shutdown") systemctl poweroff ;;
        esac
    else
        zenity --info --title="🛑 Cancelled" --text="$title cancelled by user." --timeout=2
    fi
}

# Fonction infos système détaillées
show_system_info() {
    local cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    local memory_info=$(free -h | grep Mem | awk '{print $3"/"$2}')
    local disk_info=$(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')
    local kernel_info=$(uname -r)
    local processes=$(ps aux | wc -l)
    
    zenity --info --title="📊 Sacred Machine Diagnostics" \
        --width=500 --height=300 \
        --text="⚙️ ADEPTUS MECHANICUS SYSTEM REPORT ⚙️

🖥️ CPU: $cpu_info
🧠 Memory: $memory_info used
💾 Disk: $disk_info used
🐧 Kernel: $kernel_info
⚡ Processes: $processes active
⏱️ Uptime: $UPTIME
📊 Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)
🌡️ Temperature: $TEMP

💭 \"$QUOTE\"

All systems operational. The Omnissiah protects."
    
    # Relancer le menu principal
    bash "$0"
}
