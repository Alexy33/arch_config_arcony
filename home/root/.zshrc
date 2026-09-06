# ~/.zshrc — géré par ~/github/arch_config_arcony
# Modifie ce fichier, puis lance ./dump.sh pour l'enregistrer dans le dépôt.

# ═══════════════════════════════════════════════════════ shells non interactifs
# scp, rsync, `ssh host cmd` et les outils qui lancent un shell sourcent ce
# fichier. Les alias plus bas (dont `sudo`) casseraient ces appels, donc on
# sort tout de suite si le shell n'est pas interactif.
[[ $- != *i* ]] && return

# ═══════════════════════════════════════════════════════════════════════ PATH
# `typeset -U path` déduplique automatiquement : plus besoin de vérifier si une
# entrée est déjà présente avant de l'ajouter.
typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.bun/bin"
    "$HOME/.tmuxifier/bin"
    "$HOME/scripts"
    $path
)
export PATH

export EDITOR="nvim"
export VISUAL="$EDITOR"
export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"
export BUN_INSTALL="$HOME/.bun"
export DOTFILES_PATH="$HOME/my_dotfiles/scripts"

# Ruby installe ses gems dans un chemin qui dépend de la version courante.
if command -v ruby >/dev/null 2>&1; then
    path=("$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION')/bin" $path)
fi

# fnm gère les versions de Node.
FNM_PATH="$HOME/.local/share/fnm"
if [[ -d "$FNM_PATH" ]]; then
    path=("$FNM_PATH" $path)
    eval "$(fnm env --shell zsh)"
fi

# ══════════════════════════════════════════════════════════════════════ zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    print -P "%F{33}zinit absent, installation…%f"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# ═══════════════════════════════════════════════════════════════ complétion
# compinit reconstruit un cache coûteux : une fois par jour suffit.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zinit cdreplay -q

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:*' fzf-preview 'ls -a --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -a --color $realpath'

# ══════════════════════════════════════════════════════════════════ raccourcis
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[3~' delete-char          # Suppr
bindkey '^[[1;5C' forward-word       # Ctrl+→
bindkey '^[[1;5D' backward-word      # Ctrl+←

# ═══════════════════════════════════════════════════════════════════ historique
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt extended_history          # horodate chaque commande
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks

setopt glob_dots                 # les globs voient les fichiers cachés
setopt auto_cd                   # `..` suffit pour remonter
setopt auto_pushd                # chaque cd empile, `cd -<TAB>` liste
setopt pushd_ignore_dups
setopt interactive_comments      # `# ...` accepté en ligne de commande
setopt no_beep

# ═════════════════════════════════════════════════════════════════════ alias
alias c='clear'
alias h='history | tail -20 | bat --color=always'

# eza remplace ls
alias l='eza -x --icons=always --hyperlink --color=always'
alias ls='eza -x --icons=always --hyperlink --color=always -a'
alias ll='eza -alx --icons=always --hyperlink --color=always'
alias tree='eza -aTx --icons=always --hyperlink --color=always -I ".git"'

# fastfetch
alias nf='~/.config/fastfetch/adaptive-fetch.sh'
alias pf='~/.config/fastfetch/adaptive-fetch.sh'
alias ff='~/.config/fastfetch/adaptive-fetch.sh'
alias clear='clear && ff'

# git
alias train_de_la_hype="sh $DOTFILES_PATH/push_that.sh"
alias ramene_le_coton='git pull'

# coding style Epitech
alias gestapo="sh $DOTFILES_PATH/coding-style.sh . ."
alias documents_secret_defense='cat coding-style-reports.log'
alias censure='rm -f coding-style-reports.log'
alias appel_du_parti='gestapo && documents_secret_defense && censure'

# make
alias run='make run'
alias tests='make run_tests'
alias fclean='make fclean'
alias re='make re'
alias cr='cargo build && sleep 0.2 && cargo run && cargo clean'

# tclock
alias clock='tclock -c Yellow'
alias timer='tclock timer -P -d'
alias countdown='tclock countdown -t'
alias chrono='tclock stopwatch'

# divers
alias zshrc="$EDITOR ~/.zshrc"
alias http_python_server='python3 -m http.server'
alias template='cp -r ~/template/include . && cp -r ~/template/src . && cp ~/template/Makefile . && cp -r ~/template/tests . && cp ~/template/.gitignore . && cp -r ~/template/assets . && bear -- make && fclean'
alias ta='tmux attach'
alias learning='/home/omnimessie/github/Learning_motivation/learning.sh'
alias exegol='sudo -E $HOME/.local/bin/exegol'

# Mise à jour manuelle. Le timer arch-autoupdate fait déjà les dépôts officiels
# au démarrage ; ceci ajoute l'AUR, que le timer ne peut pas gérer (yay refuse
# de tourner en root).
alias maj='yay -Syu'
alias update-log='journalctl -u arch-autoupdate.service -n 50 --no-pager'

# Sauvegarde de la configuration dans le dépôt.
alias arcony='cd ~/github/arch_config_arcony && ./dump.sh'

# La blague : `sudo` refuse, `please` obéit. Placé après le `return` du mode non
# interactif, donc les scripts ne sont pas affectés.
alias please='/usr/bin/sudo'
alias sudo='echo "say : please"'

# ═══════════════════════════════════════════════════════════════════ intégrations
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
fi
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ═══════════════════════════════════════════════════════════════════ accueil
[[ -x ~/.config/fastfetch/adaptive-fetch.sh ]] && ~/.config/fastfetch/adaptive-fetch.sh
