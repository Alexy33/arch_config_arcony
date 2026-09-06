#!/usr/bin/env bash
#
# dump.sh — capture l'etat de la machine dans ce depot.
#
# Relance-le quand tu veux : il ecrase les copies precedentes pour que le depot
# reflete exactement la machine (les suppressions sont propagees). Rien n'est
# lu en dehors de $HOME et de /etc, et rien de sensible n'est copie.
#
#   ./dump.sh            capture tout
#   ./dump.sh --list     montre ce qui serait capture, sans rien ecrire
#
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

DRY=0
[[ "${1:-}" == "--list" || "${1:-}" == "-n" ]] && DRY=1

# ---------------------------------------------------------------------------
# Ce qu'on capture. Ajoute simplement une entree ici pour etendre la capture.
# ---------------------------------------------------------------------------

# Fichiers a la racine de $HOME.
HOME_FILES=(
    .zshrc .zprofile .bashrc .bash_profile .bash_logout .gitconfig .tmux.conf
)

# Repertoires reels de ~/.config (les symlinks sont traites a part).
CONFIG_DIRS=(
    btop htop lazygit mako wireshark keepassxc rtk pacseek mpv nautilus
    procps glib-2.0 menus git go ghc lftp openstego yay
)

# Fichiers isoles de ~/.config.
CONFIG_FILES=(
    mimeapps.list user-dirs.dirs user-dirs.locale pavucontrol.ini
    spotify-flags.conf QtProject.conf
)

# Fichiers systeme. Tous lisibles sans sudo sur cette machine.
ETC_FILES=(
    /etc/hostname
    /etc/hosts
    /etc/locale.conf
    /etc/locale.gen
    /etc/vconsole.conf
    /etc/environment
    /etc/mkinitcpio.conf
    /etc/default/grub
    /etc/pacman.conf
    /etc/makepkg.conf
    /etc/tlp.conf
    /etc/systemd/zram-generator.conf
    /etc/X11/xorg.conf.d/00-keyboard.conf
    # Mise a jour automatique au demarrage (installee par restore.sh).
    /etc/systemd/system/arch-autoupdate.service
    /etc/systemd/system/arch-autoupdate.timer
    /usr/local/bin/arch-autoupdate
)
ETC_DIRS=(
    /etc/sddm.conf.d
)

# Themes GRUB installes localement (les officiels sont fournis par les paquets).
GRUB_THEMES=( minegrub minegrub-world-selection )

# Themes SDDM non fournis par un paquet.
SDDM_THEMES=( sequoia )

# ---------------------------------------------------------------------------

run() {
    if (( DRY )); then
        printf '%s\n' "${C_DIM}    [dry-run] $*${C_RESET}"
    else
        "$@"
    fi
}

# Ecrit sur stdout vers un fichier du depot, ou l'affiche en dry-run.
emit() {
    local dest="$1"
    if (( DRY )); then
        printf '%s\n' "${C_DIM}    [dry-run] écrirait $dest${C_RESET}"
        cat >/dev/null
    else
        mkdir -p "$(dirname "$dest")"
        cat > "$dest"
    fi
}

cd "$REPO_ROOT"
(( DRY )) && warn "mode --list : aucune écriture"

# ============================================================ 1. manifestes ==
section "Manifestes"

info "Paquets"
pacman -Qqen | emit manifests/pkg-native.txt
log "$(pacman -Qqen | wc -l) paquets des dépôts officiels"

pacman -Qqem | emit manifests/pkg-aur.txt
log "$(pacman -Qqem | wc -l) paquets AUR"

# La liste complete sert de reference de diff ; elle n'est pas rejouee telle
# quelle par restore.sh (qui distingue depots officiels et AUR).
pacman -Qqe | emit manifests/pkg-all-explicit.txt

if have flatpak; then
    flatpak list --app --columns=application 2>/dev/null | emit manifests/flatpak.txt
    log "$(flatpak list --app 2>/dev/null | wc -l) applications flatpak"
fi

info "Chaînes de développement"
if have rustup; then
    rustup toolchain list 2>/dev/null | awk '{print $1}' | emit manifests/rustup-toolchains.txt
fi
if [[ -d "$HOME/.cargo/bin" ]]; then
    # Les binaires installes par `cargo install` uniquement : rustup pose ses
    # propres shims (cargo, rustc, ...) qu'il ne faut pas reinstaller.
    cargo install --list 2>/dev/null | grep -E '^[a-zA-Z0-9_-]+ v' | awk '{print $1}' \
        | emit manifests/cargo.txt
fi
if have pipx; then
    pipx list --short 2>/dev/null | awk '{print $1}' | emit manifests/pipx.txt
fi
if have npm; then
    # `basename` sur les chemins perdrait le scope (@anthropic-ai/claude-code
    # deviendrait claude-code), d'ou le decoupage sur l'arbre affiche : on
    # retire les caracteres de branche puis le `@version` final.
    npm ls -g --depth=0 2>/dev/null | tail -n +2 \
        | sed -E 's/^[^a-zA-Z@]*//; s/@[^@]*$//' \
        | grep -vE '^(npm)?$' | emit manifests/npm-global.txt
fi

info "Services et système"
systemctl list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
    | awk '{print $1}' | emit manifests/services-system.txt
systemctl --user list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
    | awk '{print $1}' | emit manifests/services-user.txt
id -nG | tr ' ' '\n' | grep -v "^$USER$" | emit manifests/groups.txt

{
    echo "# Généré par dump.sh le $(date -Iseconds)"
    echo "hostname=$(cat /etc/hostname 2>/dev/null)"
    echo "kernel=$(uname -r)"
    echo "shell=$(getent passwd "$USER" | cut -d: -f7)"
    echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
    echo "gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller' | cut -d: -f3- | sed 's/^ *//' | paste -sd'; ')"
    echo "timezone=$(timedatectl show -p Timezone --value 2>/dev/null)"
    echo "locale=$(. /etc/locale.conf 2>/dev/null; echo "${LANG:-}")"
    echo "keymap=$(. /etc/vconsole.conf 2>/dev/null; echo "${KEYMAP:-}")"
    echo "bootloader=$([[ -d /boot/grub ]] && echo grub || echo autre)"
    echo "firmware=$([[ -d /sys/firmware/efi ]] && echo uefi || echo bios)"
    echo "ml4w_version=$(cat "$HOME/.config/ml4w/version/"* 2>/dev/null | head -1)"
} | emit manifests/system-info.txt

info "Dépôts git de ~/github"
{
    echo "# nom<TAB>url — rejoué par restore.sh (phase repos)"
    for d in "$HOME"/github/*/; do
        url=$(git -C "$d" remote get-url origin 2>/dev/null) || continue
        printf '%s\t%s\n' "$(basename "$d")" "$url"
    done
} | emit manifests/repos.txt

# ================================================================ 2. $HOME ==
section "Configuration utilisateur"

info "Fichiers de ~"
for f in "${HOME_FILES[@]}"; do
    src="$HOME/$f"
    # ~/.tmux.conf est un symlink casse sur cette machine : on suit la vraie
    # source dans my_dotfiles plutot que de copier un lien mort.
    [[ -f "$src" ]] || continue
    run copy_file "$src" "home/root/$f"
    log "$f"
done

info "~/dotfiles (ML4W personnalisé)"
# Le cache ML4W est integralement regenere au premier lancement : on ne garde
# que les images de profil, qui sont un choix de l'utilisateur.
run sync_dir "$HOME/dotfiles" "home/dotfiles" \
    --exclude '.config/ml4w/cache/wallpaper-generated/' \
    --exclude '.config/ml4w/cache/blurred_wallpaper.png' \
    --exclude '.config/ml4w/cache/square_wallpaper.png' \
    --exclude '.config/ml4w/cache/current_wallpaper*' \
    --exclude '*.backup-*' \
    --exclude '.git/'

info "~/my_dotfiles (absorbé — ce dépôt est la source de vérité)"
run sync_dir "$HOME/my_dotfiles" "home/my_dotfiles" \
    --exclude '.git/' \
    --exclude 'grub/minegrub*/.git/' \
    --exclude '*.bak' \
    --exclude 'scripts/discord'

info "Répertoires réels de ~/.config"
for d in "${CONFIG_DIRS[@]}"; do
    src="$HOME/.config/$d"
    [[ -d "$src" && ! -L "$src" ]] || continue
    run sync_dir "$src" "home/config/$d"
    log "$d"
done

# Les units systemd utilisateur : on garde les fichiers d'unite, pas les
# repertoires *.wants qui sont regeneres par `systemctl --user enable`.
if [[ -d "$HOME/.config/systemd/user" ]]; then
    run sync_dir "$HOME/.config/systemd/user" "home/config/systemd/user" \
        --exclude '*.wants/' --exclude '*.requires/'
    log "systemd/user"
fi

for f in "${CONFIG_FILES[@]}"; do
    [[ -f "$HOME/.config/$f" ]] || continue
    run copy_file "$HOME/.config/$f" "home/config/$f"
    log "$f"
done

info "Carte des symlinks de ~/.config"
# restore.sh rejoue cette carte pour retrouver le meme cablage :
# ~/.config/hypr → ~/dotfiles/.config/hypr, etc.
{
    echo "# lien<TAB>cible — chemins relatifs à \$HOME. Rejoué par restore.sh."
    for l in "$HOME"/.config/*; do
        [[ -L "$l" ]] || continue
        target=$(readlink "$l")
        printf '%s\t%s\n' "${l#"$HOME"/}" "${target#"$HOME"/}"
    done
    for l in "$HOME"/.[!.]*; do
        [[ -L "$l" ]] || continue
        target=$(readlink "$l")
        # Les liens Steam sont recrees par Steam lui-meme.
        [[ "$target" == *"/.steam/"* ]] && continue
        # Un lien qui pointe sur lui-meme est un lien mort : on ne le rejoue pas.
        [[ "$target" == "./$(basename "$l")" ]] && continue
        printf '%s\t%s\n' "${l#"$HOME"/}" "${target#"$HOME"/}"
    done
} | emit manifests/symlinks.txt
log "$(grep -vc '^#' manifests/symlinks.txt 2>/dev/null || echo 0) liens enregistrés"

info "Scripts de ~/.local/bin"
# On ne garde que les scripts ecrits a la main. Le tri se fait sur trois
# sources d'appartenance, de la plus fiable a la moins fiable :
#   1. les fichiers RECORD de pip listent exactement les scripts qu'il a poses
#      (pwntools, ROPgadget, pyserial...) ;
#   2. pacman -Qo pour ce qui vient d'un paquet ;
#   3. le contenu, pour les shims pipx.
# Les binaires compiles (rtk) sont ecartes par le test sur le type MIME : ils
# se reinstallent depuis leur propre source, pas depuis ce depot.
pip_owned=$(
    /usr/bin/grep -h -oE '(\.\./)*bin/[^,]+' \
        "$HOME"/.local/lib/python*/site-packages/*.dist-info/RECORD 2>/dev/null \
        | xargs -r -n1 basename | sort -u
)
# Miroir exact : les scripts supprimes de ~/.local/bin disparaissent du depot.
run rm -rf "home/local-bin"
count=0
for f in "$HOME"/.local/bin/*; do
    [[ -f "$f" && ! -L "$f" ]] || continue
    base=$(basename "$f")
    file --mime-type -b "$f" 2>/dev/null | /usr/bin/grep -q '^text/' || continue
    /usr/bin/grep -qxF "$base" <<< "$pip_owned" && continue
    /usr/bin/grep -qE '\.local/share/pipx|EASY-INSTALL' "$f" 2>/dev/null && continue
    pacman -Qoq "$f" >/dev/null 2>&1 && continue
    run copy_file "$f" "home/local-bin/$base"
    log "$base"
    ((count++))
done
log "$count scripts personnels"

info "Paquets Python installés pour l'utilisateur"
# Best-effort : ces paquets sont mieux servis par pacman ou pipx, mais les
# lister evite de decouvrir leur absence au milieu d'un exercice.
if have pip; then
    pip list --user --format=freeze 2>/dev/null | emit manifests/pip-user.txt
fi

# ================================================================ 3. /etc ===
section "Configuration système"

for f in "${ETC_FILES[@]}"; do
    # Absent = pas encore installe sur cette machine : on garde la copie du
    # depot plutot que de la supprimer.
    [[ -e "$f" ]] || { log "${C_DIM}absent, copie du dépôt conservée : $f${C_RESET}"; continue; }
    [[ -r "$f" ]] || { warn "illisible, ignoré : $f"; continue; }
    run copy_file "$f" "system${f}"
    log "${f}"
done
for d in "${ETC_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    run sync_dir "$d" "system${d}"
    log "${d}/"
done

# =============================================================== 4. assets ==
section "Assets"

info "Fonds d'écran"
run sync_dir "$HOME/wallpaper" "assets/wallpaper"
log "$(find "$HOME/wallpaper" -maxdepth 1 -type f 2>/dev/null | wc -l) images"

info "Thèmes SDDM"
for t in "${SDDM_THEMES[@]}"; do
    src="/usr/share/sddm/themes/$t"
    [[ -d "$src" ]] || continue
    pacman -Qoq "$src" >/dev/null 2>&1 && { log "$t fourni par un paquet, ignoré"; continue; }
    run sync_dir "$src" "assets/sddm-themes/$t"
    log "$t"
done

info "Thèmes GRUB"
for t in "${GRUB_THEMES[@]}"; do
    src="/boot/grub/themes/$t"
    [[ -d "$src" ]] || continue
    run sync_dir "$src" "assets/grub-themes/$t"
    log "$t"
done

# ============================================================== 5. resume ===
section "Terminé"
if (( DRY )); then
    ok "dry-run terminé — rien n'a été écrit"
else
    ok "dépôt à jour ($(du -sh "$REPO_ROOT" --exclude=.git 2>/dev/null | cut -f1))"
    printf '\n'
    if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        changed=$(git -C "$REPO_ROOT" status --porcelain | wc -l)
        if (( changed )); then
            log "$changed chemins modifiés — pense à commit :"
            printf '%s\n' "    ${C_BOLD}git add -A && git commit -m \"dump $(date +%F)\" && git push${C_RESET}"
        else
            log "aucun changement depuis le dernier dump"
        fi
    fi
fi
