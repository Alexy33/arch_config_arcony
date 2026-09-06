#!/usr/bin/env bash
# Fonctions partagees par dump.sh et restore.sh.
# Ce fichier n'est pas executable directement : il est source.

set -uo pipefail

# ---------------------------------------------------------------- chemins ----
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# ---------------------------------------------------------------- couleurs ---
if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
    C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'
    C_BLUE=$'\e[34m'; C_CYAN=$'\e[96m'; C_MAGENTA=$'\e[95m'
else
    C_RESET=''; C_BOLD=''; C_DIM=''
    C_RED=''; C_GREEN=''; C_YELLOW=''
    C_BLUE=''; C_CYAN=''; C_MAGENTA=''
fi

# ---------------------------------------------------------------- logging ----
log()      { printf '%s\n' "${C_DIM}  ·${C_RESET} $*"; }
info()     { printf '%s\n' "${C_CYAN}${C_BOLD}==>${C_RESET}${C_BOLD} $*${C_RESET}"; }
ok()       { printf '%s\n' "${C_GREEN}  ✔${C_RESET} $*"; }
warn()     { printf '%s\n' "${C_YELLOW}  ⚠${C_RESET} $*" >&2; }
err()      { printf '%s\n' "${C_RED}  ✘${C_RESET} $*" >&2; }
die()      { err "$*"; exit 1; }

section() {
    printf '\n%s\n' "${C_MAGENTA}${C_BOLD}┌─ $* ${C_RESET}"
}

# Demande oui/non. Respecte $ASSUME_YES pour tourner sans interaction.
confirm() {
    local prompt="${1:-Continuer ?}"
    if [[ "${ASSUME_YES:-0}" == "1" ]]; then
        log "${prompt} ${C_DIM}(--yes)${C_RESET}"
        return 0
    fi
    local reply
    read -r -p "${C_CYAN}${C_BOLD}?${C_RESET} ${prompt} [o/N] " reply
    [[ "$reply" =~ ^([oOyY])$ ]]
}

# ---------------------------------------------------------------- helpers ----
have() { command -v "$1" >/dev/null 2>&1; }

# rsync avec des defauts surs : miroir exact, pas de fichiers speciaux.
sync_dir() {
    local src="$1" dst="$2"; shift 2
    [[ -d "$src" ]] || { warn "source absente, ignoree : $src"; return 0; }
    mkdir -p "$dst"
    rsync -a --delete --safe-links "$@" "${src%/}/" "${dst%/}/"
}

# Copie un fichier en creant l'arborescence, sans rien casser s'il manque.
copy_file() {
    local src="$1" dst="$2"
    [[ -f "$src" ]] || { warn "fichier absent, ignore : $src"; return 0; }
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
}

# Horodatage utilise pour les repertoires de sauvegarde.
timestamp() { date +%Y%m%d-%H%M%S; }

# Deplace une cible existante dans le repertoire de backup au lieu de l'ecraser.
# Utilise par restore.sh : rien n'est jamais detruit en silence.
backup_path() {
    local target="$1" backup_root="$2"
    [[ -e "$target" || -L "$target" ]] || return 0
    local rel="${target#"$HOME"/}"
    local dest="$backup_root/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$target" "$dest"
    log "sauvegarde : ${target/#$HOME/\~} → ${dest/#$HOME/\~}"
}
