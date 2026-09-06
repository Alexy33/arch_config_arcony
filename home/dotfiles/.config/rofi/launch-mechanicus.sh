#!/bin/bash
# ⚙️ ENHANCED MECHANICUS LAUNCHER ⚙️

get_time_message() {
    local hour=$(date +%H)
    
    if [ $hour -ge 6 ] && [ $hour -lt 12 ]; then
        # Matin
        local messages=(
            "Morning forge ignition sequence"
            "Dawn protocols initializing" 
            "Sacred algorithms awakening"
            "First light of the Omnissiah"
            "Machine spirits stirring"
        )
    elif [ $hour -ge 12 ] && [ $hour -lt 18 ]; then
        # Jour  
        local messages=(
            "Productivity rituals engaged"
            "Knowledge acquisition protocols"
            "Peak efficiency algorithms"
            "Sacred work continues"
            "Machine spirits fully active"
        )
    elif [ $hour -ge 18 ] && [ $hour -lt 22 ]; then
        # Soir
        local messages=(
            "Evening data compilation"
            "Rest cycle preparation"
            "Archive protocols active" 
            "Twilight of the machine"
            "End cycle rituals"
        )
    else
        # Nuit
        local messages=(
            "Night watch protocols"
            "Silent meditation mode"
            "Guardian algorithms active"
            "Deep sleep cycles"
            "Omnissiah vigil continues"
        )
    fi
    
    echo "${messages[$RANDOM % ${#messages[@]}]}"
}

# Créer le thème selon l'heure
create_time_theme() {
    local hour=$(date +%H)
    local theme_file="$HOME/.config/rofi/mechanicus-current.rasi"
    
    # Couleurs de base selon l'heure
    if [ $hour -ge 6 ] && [ $hour -lt 12 ]; then
        # Matin - Rouge énergique
        local main_color="#ff4141"
        local bright_color="#ff6b6b" 
        local bg_tint="rgba(20, 10, 10, 0.96)"
        local selected_bg="rgba(90, 42, 42, 0.8)"
    elif [ $hour -ge 12 ] && [ $hour -lt 18 ]; then
        # Jour - Vert standard
        local main_color="#00ff41"
        local bright_color="#39ff14"
        local bg_tint="rgba(10, 15, 10, 0.96)"
        local selected_bg="rgba(42, 90, 42, 0.8)"
    elif [ $hour -ge 18 ] && [ $hour -lt 22 ]; then
        # Soir - Bleu relaxant
        local main_color="#4169ff"
        local bright_color="#6b8fff"
        local bg_tint="rgba(10, 10, 20, 0.96)"
        local selected_bg="rgba(42, 42, 90, 0.8)"
    else
        # Nuit - Violet mystique
        local main_color="#8a41ff"
        local bright_color="#a66bff"
        local bg_tint="rgba(15, 10, 20, 0.96)"
        local selected_bg="rgba(66, 42, 90, 0.8)"
    fi

    # Créer le thème adaptatif
    cat > "$theme_file" << THEME_EOF
* {
    bg-main: #0a0a0a;
    bg-secondary: #1a1a1a;
    bg-selected: $selected_bg;
    
    fg-main: #cccccc;
    fg-bright: $bright_color;
    fg-dim: #888888;
    
    border-main: $main_color;
    border-bright: $bright_color;
    
    accent-gold: #ffd700;
    
    background-color: transparent;
    text-color: @fg-main;
    border-color: @border-main;
    selected-normal-background: @bg-selected;
    selected-normal-foreground: @fg-bright;
}

window {
    transparency: "real";
    background-color: $bg_tint;
    border: 4px;
    border-color: @border-main;
    border-radius: 18px;
    width: 980px;
    height: 650px;
    padding: 0px;
    location: center;
    anchor: center;
}

mainbox {
    background-color: transparent;
    children: [ "mode-switcher", "inputbar", "listview" ];
    padding: 20px;
    spacing: 12px;
}

mode-switcher {
    background-color: rgba(26, 26, 26, 0.8);
    border: 2px;
    border-color: @border-main;
    border-radius: 10px;
    padding: 8px;
    spacing: 8px;
    orientation: horizontal;
    expand: false;
}

button {
    background-color: rgba(15, 15, 15, 0.7);
    text-color: @fg-dim;
    border: 2px;
    border-color: @border-main;
    border-radius: 8px;
    padding: 8px 16px;
    font: "JetBrainsMono Nerd Font Bold 10";
    cursor: pointer;
    expand: true;
}

button selected {
    background-color: @border-main;
    text-color: @bg-main;
    border: 2px;
    border-color: @border-bright;
    font: "JetBrainsMono Nerd Font Bold 11";
}

inputbar {
    background-color: rgba(20, 20, 20, 0.9);
    border: 3px;
    border-color: @border-main;
    border-radius: 12px;
    padding: 12px 18px;
    spacing: 12px;
    children: [ "prompt", "textbox-prompt-colon", "entry" ];
}

prompt {
    background-color: transparent;
    text-color: @accent-gold;
    font: "JetBrainsMono Nerd Font Bold 12";
    vertical-align: 0.5;
}

textbox-prompt-colon {
    expand: false;
    str: ">>>";
    text-color: @border-bright;
    font: "JetBrainsMono Nerd Font Bold 12";
    vertical-align: 0.5;
}

entry {
    background-color: transparent;
    text-color: @fg-bright;
    placeholder: "Invoke Sacred Machine Spirit Protocol...";
    cursor-color: @border-bright;
    font: "JetBrainsMono Nerd Font 11";
    vertical-align: 0.5;
}

listview {
    background-color: rgba(8, 8, 8, 0.95);
    border: 3px;
    border-color: @border-main;
    border-radius: 15px;
    padding: 15px;
    spacing: 6px;
    lines: 16;
    columns: 1;
    cycle: true;
    dynamic: true;
    scrollbar: true;
    fixed-height: true;
    reverse: false;
    flow: vertical;
}

scrollbar {
    background-color: @bg-secondary;
    handle-color: @border-main;
    handle-width: 8px;
    border-radius: 4px;
    margin: 0px 2px 0px 6px;
}

element {
    background-color: transparent;
    border-radius: 10px;
    padding: 12px 18px;
    spacing: 16px;
    text-color: @fg-main;
    orientation: horizontal;
    cursor: pointer;
    border: 2px;
    border-color: transparent;
}

element normal.normal {
    background-color: transparent;
    text-color: @fg-main;
    border-color: transparent;
}

element alternate.normal {
    background-color: rgba(12, 12, 12, 0.6);
    text-color: @fg-main;
    border-color: transparent;
}

element selected.normal {
    background-color: @bg-selected;
    text-color: @fg-bright;
    border: 3px;
    border-color: @border-bright;
    font: "JetBrainsMono Nerd Font Bold 11";
    margin: -1px;
    padding: 14px 20px;
}

element-icon {
    size: 36px;
    margin: 0px 12px 0px 0px;
    vertical-align: 0.5;
    horizontal-align: 0.5;
}

element-text {
    vertical-align: 0.5;
    horizontal-align: 0.0;
    font: "JetBrainsMono Nerd Font 11";
    margin: 2px 0px 2px 2px;
    expand: true;
}
THEME_EOF
}

# ═══════════════════════════════════════════════════════════
# LANCEMENT PRINCIPAL
# ═══════════════════════════════════════════════════════════

# Créer le thème adaptatif
create_time_theme

# Obtenir le message aléatoire
MESSAGE=$(get_time_message)

# Lancer rofi avec le thème dynamique
rofi -show drun \
     -theme ~/.config/rofi/mechanicus-current.rasi \
     -display-drun "⚙️ $MESSAGE" \
     -show-icons \
     -font "JetBrainsMono Nerd Font Bold 12" \
     -sort \
     -sorting-method fzf
