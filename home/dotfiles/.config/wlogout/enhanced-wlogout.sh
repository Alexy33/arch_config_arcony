#!/bin/bash
# ⚙️ ENHANCED MECHANICUS WLOGOUT ⚙️

# Citations Mechanicus
QUOTES=(
    "The Omnissiah guides our shutdown"
    "Flesh is weak, steel endures"
    "From the weakness of the mind, save us"
    "Knowledge is power, guard it well"
    "The Machine Spirit watches over us"
    "Binary hymns soothe the processes"
    "Sacred algorithms compute destiny"
    "Through knowledge, strength"
    "Blessed be the Machine"
    "The code is eternal"
)

# Obtenir l'uptime
UPTIME=$(uptime -p | sed 's/up //')

# Citation aléatoire
QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}

# Créer un overlay avec les infos
create_info_overlay() {
    cat > /tmp/wlogout_info.txt << INFO_EOF
═══════════════════════════════════════════════════════════
⚙️ ADEPTUS MECHANICUS POWER CONTROL INTERFACE ⚙️
═══════════════════════════════════════════════════════════

🕐 Current Time: $(date '+%H:%M:%S')
⏱️  Machine Uptime: $UPTIME
🖥️  System Status: All systems operational
📊 Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)

Last System Activities:
$(journalctl --no-pager -n 3 --output=short-precise | tail -3 | sed 's/^/  /')

═══════════════════════════════════════════════════════════
💭 Omnissiah's Wisdom: "$QUOTE"
═══════════════════════════════════════════════════════════
INFO_EOF
}

# Fonction countdown pour shutdown/reboot
countdown_action() {
    local action=$1
    local action_name=$2
    
    echo "⚡ INITIATING $action_name PROTOCOL ⚡"
    echo ""
    
    for i in 5 4 3 2 1; do
        echo -ne "\r🔥 $action_name in $i seconds... (Ctrl+C to cancel)"
        sleep 1
    done
    
    echo -e "\n"
    echo "🤖 Executing $action_name protocol..."
    ~/.config/hypr/scripts/power.sh $action
}

# Afficher les infos système
show_system_info() {
    create_info_overlay
    cat /tmp/wlogout_info.txt
    echo ""
    echo "Press any key to continue to power menu..."
    read -n 1
    clear
}

# Menu principal
main_menu() {
    while true; do
        clear
        create_info_overlay
        
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║        ⚙️ ADEPTUS MECHANICUS POWER INTERFACE ⚙️        ║"  
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "⏱️  Uptime: $UPTIME"
        echo "💭 \"$QUOTE\""
        echo ""
        echo "Choose your ritual:"
        echo ""
        echo "  🔒 [L] Sacred Lock"
        echo "  ⚙️  [E] Machine Rest (Logout)"  
        echo "  💤 [S] Deep Sleep (Suspend)"
        echo "  🔄 [R] Sacred Reboot"
        echo "  ⚡ [P] Final Rest (Shutdown)"
        echo "  📊 [I] System Information"
        echo "  ❌ [Q] Cancel"
        echo ""
        echo -n "Enter your choice: "
        
        read -n 1 choice
        echo ""
        
        case ${choice,,} in
            l) ~/.config/hypr/scripts/power.sh lock; break ;;
            e) ~/.config/hypr/scripts/power.sh exit; break ;;
            s) ~/.config/hypr/scripts/power.sh suspend; break ;;
            r) countdown_action "reboot" "SACRED REBOOT"; break ;;
            p) countdown_action "shutdown" "FINAL REST"; break ;;
            i) show_system_info ;;
            q) echo "🤖 Ritual cancelled by user."; break ;;
            *) echo "❌ Invalid choice. Try again."; sleep 1 ;;
        esac
    done
}

# Lancement principal
if [ "$1" = "--gui" ]; then
    # Lancer wlogout normal avec infos en overlay
    wlogout
else
    # Mode terminal interactif
    main_menu
fi
