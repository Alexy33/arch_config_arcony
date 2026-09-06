#!/usr/bin/env bash
#
# restore.sh — remonte la machine à partir de ce dépôt.
#
# Pensé pour une Arch fraîchement installée (base + réseau + git), mais
# rejouable sans danger sur une machine déjà configurée : tout ce qui serait
# écrasé part d'abord dans ~/.arch-config-backup/<horodatage>/.
#
#   ./restore.sh                    interactif, phase par phase
#   ./restore.sh --yes              tout enchaîner sans rien demander
#   ./restore.sh --only home,assets ne jouer que ces phases
#   ./restore.sh --skip repos,aur   tout sauf ces phases
#   ./restore.sh --list             lister les phases et sortir
#
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

PHASES=(
    preflight   "vérifications préalables"
    pacman      "pacman.conf, trousseau, mise à jour du système"
    packages    "paquets des dépôts officiels"
    aur         "yay + paquets AUR"
    flatpak     "flatpak + applications ML4W"
    toolchains  "rustup, cargo, pipx, npm, bun"
    system      "fichiers /etc"
    home        "dotfiles, ~/.config, symlinks, scripts"
    assets      "fonds d'écran, thèmes SDDM et GRUB"
    services    "services systemd et groupes"
    autoupdate  "mise à jour automatique au démarrage"
    shell       "zsh par défaut + zinit"
    boot        "mkinitcpio et grub-mkconfig"
    repos       "clonage des dépôts de ~/github"
)

# ------------------------------------------------------------------ options --
ASSUME_YES=0
ONLY=""
SKIP=""

while (($#)); do
    case "$1" in
        -y|--yes)  ASSUME_YES=1 ;;
        --only)    ONLY="${2:-}"; shift ;;
        --skip)    SKIP="${2:-}"; shift ;;
        -l|--list)
            printf '%s\n' "${C_BOLD}Phases disponibles :${C_RESET}"
            for ((i=0; i<${#PHASES[@]}; i+=2)); do
                printf '  %-12s %s\n' "${PHASES[i]}" "${PHASES[i+1]}"
            done
            exit 0 ;;
        -h|--help)
            sed -n '2,16p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) die "option inconnue : $1 (voir --help)" ;;
    esac
    shift
done
export ASSUME_YES

BACKUP_ROOT="$HOME/.arch-config-backup/$(timestamp)"
# Cree tout de suite : les phases jouees seules (--only system) y ecrivent
# sans passer par preflight.
mkdir -p "$BACKUP_ROOT"

# Decide si une phase doit tourner, d'apres --only / --skip puis confirmation.
should_run() {
    local name="$1" desc="$2"
    if [[ -n "$ONLY" ]] && [[ ",$ONLY," != *",$name,"* ]]; then return 1; fi
    if [[ -n "$SKIP" ]] && [[ ",$SKIP," == *",$name,"* ]]; then
        log "phase ${C_BOLD}$name${C_RESET} ignorée (--skip)"; return 1
    fi
    section "$name — $desc"
    confirm "Jouer cette phase ?"
}

# Installe des paquets en écartant d'abord ceux qui n'existent plus, sinon
# pacman refuse toute la transaction pour un seul nom disparu.
install_pkgs() {
    local -n _list=$1; local installer=$2
    local ok_pkgs=() missing=()
    for p in "${_list[@]}"; do
        if $installer -Si "$p" >/dev/null 2>&1; then ok_pkgs+=("$p"); else missing+=("$p"); fi
    done
    if ((${#missing[@]})); then
        warn "introuvables, ignorés : ${missing[*]}"
    fi
    ((${#ok_pkgs[@]})) || { log "rien à installer"; return 0; }
    log "${#ok_pkgs[@]} paquets à installer"
    $installer -S --needed --noconfirm "${ok_pkgs[@]}"
}

# Lit un manifeste en tableau, en sautant commentaires et lignes vides.
read_manifest() {
    local file="$REPO_ROOT/manifests/$1"
    [[ -f "$file" ]] || return 1
    mapfile -t "$2" < <(grep -vE '^\s*(#|$)' "$file")
}

printf '%s\n' "${C_BOLD}${C_CYAN}"
cat <<'BANNER'
   arch_config_arcony — restauration
BANNER
printf '%s\n' "${C_RESET}"
log "sauvegardes : ${BACKUP_ROOT/#$HOME/\~}"

# ═══════════════════════════════════════════════════════════════ 1. preflight
if should_run preflight "vérifications préalables"; then
    [[ $EUID -ne 0 ]] || die "ne lance pas ce script en root : il écrit dans \$HOME."
    have pacman || die "ce script cible Arch Linux (pacman introuvable)."
    have sudo   || die "sudo est requis."
    have git    || die "git est requis."
    have rsync  || { log "installation de rsync"; sudo pacman -S --needed --noconfirm rsync; }

    if ! ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
        warn "pas de réponse d'archlinux.org — vérifie ta connexion"
        confirm "Continuer quand même ?" || exit 1
    fi

    # Un seul sudo demandé ici ; il reste valide pour la suite du script.
    sudo -v || die "sudo refusé"
    ok "environnement prêt"
    [[ -f "$REPO_ROOT/manifests/system-info.txt" ]] && \
        sed 's/^/    /' "$REPO_ROOT/manifests/system-info.txt"
fi

# ══════════════════════════════════════════════════════════════════ 2. pacman
if should_run pacman "pacman.conf, trousseau, mise à jour du système"; then
    if [[ -f "$REPO_ROOT/system/etc/pacman.conf" ]]; then
        sudo cp -a /etc/pacman.conf "$BACKUP_ROOT/pacman.conf.bak" 2>/dev/null
        sudo install -m644 "$REPO_ROOT/system/etc/pacman.conf" /etc/pacman.conf
        ok "/etc/pacman.conf restauré (multilib, ParallelDownloads…)"
    fi
    log "rafraîchissement du trousseau de clés"
    sudo pacman -Sy --needed --noconfirm archlinux-keyring
    log "mise à jour du système"
    sudo pacman -Syu --noconfirm
    ok "système à jour"
fi

# ════════════════════════════════════════════════════════════════ 3. packages
if should_run packages "paquets des dépôts officiels"; then
    if read_manifest pkg-native.txt NATIVE; then
        install_pkgs NATIVE "sudo pacman"
        ok "paquets officiels installés"
    else
        warn "manifests/pkg-native.txt absent — lance ./dump.sh d'abord"
    fi
fi

# ═════════════════════════════════════════════════════════════════════ 4. AUR
if should_run aur "yay + paquets AUR"; then
    if ! have yay; then
        log "compilation de yay"
        sudo pacman -S --needed --noconfirm base-devel git
        tmp=$(mktemp -d)
        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
        # makepkg refuse de tourner en root, d'où l'absence de sudo ici ; il
        # appellera sudo lui-même pour l'étape d'installation.
        ( cd "$tmp/yay" && makepkg -si --noconfirm )
        rm -rf "$tmp"
        have yay && ok "yay installé" || die "l'installation de yay a échoué"
    else
        log "yay déjà présent"
    fi

    if read_manifest pkg-aur.txt AUR; then
        # Les paquets AUR se compilent : c'est long, et un échec isolé ne doit
        # pas arrêter les autres, donc on les passe un par un.
        failed=()
        for p in "${AUR[@]}"; do
            log "AUR : $p"
            yay -S --needed --noconfirm --answerdiff=None --answerclean=None "$p" \
                || failed+=("$p")
        done
        ((${#failed[@]})) && warn "échecs AUR (à reprendre à la main) : ${failed[*]}"
        ok "paquets AUR traités"
    fi
fi

# ═════════════════════════════════════════════════════════════════ 5. flatpak
if should_run flatpak "flatpak + applications ML4W"; then
    have flatpak || sudo pacman -S --needed --noconfirm flatpak
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    if read_manifest flatpak.txt FLATPAKS; then
        for app in "${FLATPAKS[@]}"; do
            log "flatpak : $app"
            flatpak install --user --noninteractive --or-update flathub "$app" \
                || warn "échec : $app"
        done
    fi
    ok "flatpaks installés"
fi

# ══════════════════════════════════════════════════════════════ 6. toolchains
if should_run toolchains "rustup, cargo, pipx, npm, bun"; then
    if read_manifest rustup-toolchains.txt TOOLCHAINS; then
        have rustup || sudo pacman -S --needed --noconfirm rustup
        for tc in "${TOOLCHAINS[@]}"; do
            # Le manifeste enregistre la cible complète ; rustup accepte le
            # canal seul, ce qui reste correct si l'architecture change.
            rustup toolchain install "${tc%%-x86_64*}" || warn "toolchain : $tc"
        done
        rustup default "${TOOLCHAINS[0]%%-x86_64*}"
    fi

    if read_manifest cargo.txt CRATES; then
        for c in "${CRATES[@]}"; do
            log "cargo install $c"
            cargo install --locked "$c" || warn "échec cargo : $c"
        done
    fi

    if read_manifest pipx.txt PIPX; then
        have pipx || sudo pacman -S --needed --noconfirm python-pipx
        for p in "${PIPX[@]}"; do
            log "pipx install $p"
            pipx install "$p" || warn "échec pipx : $p"
        done
    fi

    if read_manifest npm-global.txt NPMS; then
        have npm || sudo pacman -S --needed --noconfirm npm
        for n in "${NPMS[@]}"; do
            log "npm -g $n"
            sudo npm install -g "$n" || warn "échec npm : $n"
        done
    fi

    if [[ ! -x "$HOME/.bun/bin/bun" ]]; then
        have curl || sudo pacman -S --needed --noconfirm curl
        log "installation de bun"
        curl -fsSL https://bun.sh/install | bash || warn "échec de l'installation de bun"
    fi
    ok "chaînes de développement en place"
fi

# ══════════════════════════════════════════════════════════════════ 7. système
if should_run system "fichiers /etc"; then
    # find plutôt qu'une liste en dur : tout ce que dump.sh a capturé sous
    # system/ est remis à la même place, permissions comprises.
    while IFS= read -r -d '' src; do
        dest="${src#"$REPO_ROOT"/system}"
        if [[ -e "$dest" ]]; then
            sudo mkdir -p "$BACKUP_ROOT/system$(dirname "$dest")"
            sudo cp -a "$dest" "$BACKUP_ROOT/system$dest" 2>/dev/null
        fi
        sudo mkdir -p "$(dirname "$dest")"
        sudo cp -a "$src" "$dest"
        log "${dest}"
    done < <(find "$REPO_ROOT/system" -type f -print0)

    # locale.gen restauré : il faut regénérer les locales pour que LANG marche.
    if [[ -f "$REPO_ROOT/system/etc/locale.gen" ]]; then
        sudo locale-gen
    fi
    ok "/etc restauré (sauvegarde dans ${BACKUP_ROOT/#$HOME/\~}/system)"
fi

# ═════════════════════════════════════════════════════════════════════ 8. home
if should_run home "dotfiles, ~/.config, symlinks, scripts"; then
    mkdir -p "$HOME/.config" "$HOME/.local/bin"

    # --- ~/dotfiles et ~/my_dotfiles ---------------------------------------
    # Ce sont des répertoires réels (pas des liens) : ML4W et les scripts y
    # écrivent, et ~/.config pointe dessus.
    for pair in "dotfiles:$HOME/dotfiles" "my_dotfiles:$HOME/my_dotfiles"; do
        name="${pair%%:*}"; dest="${pair#*:}"
        [[ -d "$REPO_ROOT/home/$name" ]] || continue
        backup_path "$dest" "$BACKUP_ROOT"
        mkdir -p "$dest"
        rsync -a "$REPO_ROOT/home/$name/" "$dest/"
        ok "~/${name}"
    done

    # --- fichiers de ~ ------------------------------------------------------
    for f in "$REPO_ROOT"/home/root/.*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        backup_path "$HOME/$base" "$BACKUP_ROOT"
        cp -a "$f" "$HOME/$base"
        log "~/$base"
    done

    # --- ~/.config (répertoires et fichiers réels) --------------------------
    if [[ -d "$REPO_ROOT/home/config" ]]; then
        for entry in "$REPO_ROOT"/home/config/*; do
            [[ -e "$entry" ]] || continue
            base=$(basename "$entry")
            backup_path "$HOME/.config/$base" "$BACKUP_ROOT"
            cp -a "$entry" "$HOME/.config/$base"
            log "~/.config/$base"
        done
    fi

    # --- symlinks -----------------------------------------------------------
    # Rejoue exactement le câblage capturé : ~/.config/hypr → ~/dotfiles/…
    if [[ -f "$REPO_ROOT/manifests/symlinks.txt" ]]; then
        n=0
        while IFS=$'\t' read -r link target; do
            [[ "$link" == \#* || -z "$link" ]] && continue
            abs_link="$HOME/$link"
            # Les cibles ont été enregistrées relatives à $HOME quand elles y
            # étaient ; les chemins absolus (/usr/...) sont laissés tels quels.
            [[ "$target" == /* ]] && abs_target="$target" || abs_target="$HOME/$target"
            if [[ ! -e "$abs_target" ]]; then
                warn "cible absente, lien non créé : $link → $target"
                continue
            fi
            backup_path "$abs_link" "$BACKUP_ROOT"
            mkdir -p "$(dirname "$abs_link")"
            ln -s "$abs_target" "$abs_link"
            ((n++))
        done < "$REPO_ROOT/manifests/symlinks.txt"
        ok "$n symlinks recréés"
    fi

    # --- scripts personnels -------------------------------------------------
    if [[ -d "$REPO_ROOT/home/local-bin" ]]; then
        for s in "$REPO_ROOT"/home/local-bin/*; do
            [[ -f "$s" ]] || continue
            install -Dm755 "$s" "$HOME/.local/bin/$(basename "$s")"
        done
        ok "scripts de ~/.local/bin installés"
    fi
fi

# ═══════════════════════════════════════════════════════════════════ 9. assets
if should_run assets "fonds d'écran, thèmes SDDM et GRUB"; then
    if [[ -d "$REPO_ROOT/assets/wallpaper" ]]; then
        mkdir -p "$HOME/wallpaper"
        rsync -a "$REPO_ROOT/assets/wallpaper/" "$HOME/wallpaper/"
        ok "$(find "$HOME/wallpaper" -maxdepth 1 -type f | wc -l) fonds d'écran"
    fi

    for t in "$REPO_ROOT"/assets/sddm-themes/*/; do
        [[ -d "$t" ]] || continue
        name=$(basename "$t")
        sudo mkdir -p "/usr/share/sddm/themes/$name"
        sudo rsync -a "$t" "/usr/share/sddm/themes/$name/"
        ok "thème SDDM : $name"
    done

    for t in "$REPO_ROOT"/assets/grub-themes/*/; do
        [[ -d "$t" ]] || continue
        name=$(basename "$t")
        sudo mkdir -p "/boot/grub/themes/$name"
        sudo rsync -a "$t" "/boot/grub/themes/$name/"
        ok "thème GRUB : $name"
    done
fi

# ══════════════════════════════════════════════════════════════════ 10. services
if should_run services "services systemd et groupes"; then
    if read_manifest groups.txt GROUPS; then
        for g in "${GROUPS[@]}"; do
            getent group "$g" >/dev/null 2>&1 || { warn "groupe inexistant : $g"; continue; }
            sudo usermod -aG "$g" "$USER" && log "groupe : $g"
        done
        warn "les nouveaux groupes ne prennent effet qu'après reconnexion"
    fi

    if read_manifest services-system.txt SYS_SVC; then
        for s in "${SYS_SVC[@]}"; do
            # Les units modèles (getty@.service) ne s'activent pas telles quelles.
            [[ "$s" == *@.* ]] && continue
            systemctl cat "$s" >/dev/null 2>&1 || { warn "unit absente : $s"; continue; }
            sudo systemctl enable "$s" >/dev/null 2>&1 && log "activé : $s" || warn "échec : $s"
        done
    fi

    systemctl --user daemon-reload 2>/dev/null
    if read_manifest services-user.txt USR_SVC; then
        for s in "${USR_SVC[@]}"; do
            [[ "$s" == *@.* ]] && continue
            systemctl --user enable "$s" >/dev/null 2>&1 && log "activé (user) : $s" \
                || warn "échec (user) : $s"
        done
    fi
    ok "services configurés"
fi

# ════════════════════════════════════════════════════════════════ 11. autoupdate
if should_run autoupdate "mise à jour automatique au démarrage"; then
    warn "rappel : une mise à jour Arch non supervisée peut casser le système"
    warn "(interventions manuelles annoncées sur archlinux.org, modules noyau"
    warn " désynchronisés avant redémarrage). L'AUR reste manuel : \`maj\`."
    if confirm "Activer arch-autoupdate.timer ?"; then
        sudo systemctl daemon-reload
        sudo systemctl enable --now arch-autoupdate.timer
        ok "activé — déclenchement 3 min après chaque démarrage, puis chaque jour"
        log "journal : journalctl -u arch-autoupdate.service"
        systemctl list-timers arch-autoupdate.timer --no-pager 2>/dev/null | head -3
    fi
fi

# ═════════════════════════════════════════════════════════════════════ 12. shell
if should_run shell "zsh par défaut + zinit"; then
    have zsh || sudo pacman -S --needed --noconfirm zsh
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" != */zsh ]]; then
        sudo chsh -s "$(command -v zsh)" "$USER" && ok "shell par défaut : zsh"
    else
        log "zsh est déjà le shell par défaut"
    fi

    ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    if [[ ! -d "$ZINIT_HOME" ]]; then
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        ok "zinit installé"
    fi
    log "les plugins zinit se téléchargent au premier lancement de zsh"
fi

# ══════════════════════════════════════════════════════════════════════ 13. boot
if should_run boot "mkinitcpio et grub-mkconfig"; then
    if [[ -f "$REPO_ROOT/system/etc/mkinitcpio.conf" ]]; then
        confirm "Regénérer les initramfs (mkinitcpio -P) ?" && sudo mkinitcpio -P
    fi
    if [[ -d /boot/grub ]] && have grub-mkconfig; then
        confirm "Regénérer la configuration GRUB ?" && sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    ok "démarrage configuré"
fi

# ═════════════════════════════════════════════════════════════════════ 14. repos
if should_run repos "clonage des dépôts de ~/github"; then
    if read_manifest repos.txt REPOS; then
        mkdir -p "$HOME/github"
        for line in "${REPOS[@]}"; do
            name="${line%%$'\t'*}"; url="${line#*$'\t'}"
            dest="$HOME/github/$name"
            if [[ -d "$dest/.git" ]]; then
                log "déjà présent : $name"
            elif git clone "$url" "$dest" 2>/dev/null; then
                ok "cloné : $name"
            else
                # Les URL git@ demandent une clé SSH, volontairement absente du
                # dépôt : c'est attendu tant que ~/.ssh n'est pas restauré.
                warn "échec : $name ($url)"
            fi
        done
    fi
fi

# ══════════════════════════════════════════════════════════════════════ résumé
section "Terminé"
ok "restauration effectuée"
printf '\n%s\n' "${C_BOLD}Ce que ce dépôt ne contient pas, à remettre à la main :${C_RESET}"
cat <<'MANUEL'
    ~/.ssh          clés SSH (sinon les clones git@ échouent)
    ~/.gnupg        clés GPG
    KeePassXC       la base .kdbx elle-même
    NetworkManager  connexions Wi-Fi (/etc/NetworkManager/system-connections)
    Tailscale       `sudo tailscale up` pour ré-authentifier
    Steam / Discord comptes et bibliothèques
MANUEL
printf '\n%s\n' "${C_BOLD}Ensuite :${C_RESET}"
printf '%s\n' "    1. déconnecte-toi et reconnecte-toi (groupes docker/vboxusers, shell zsh)"
printf '%s\n' "    2. au premier zsh, zinit télécharge ses plugins — laisse-le finir"
printf '%s\n' "    3. redémarre pour SDDM, Hyprland et les initramfs"
printf '\n%s\n' "${C_DIM}sauvegardes conservées dans ${BACKUP_ROOT/#$HOME/\~}${C_RESET}"
