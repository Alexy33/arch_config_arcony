# arch_config_arcony

Ma configuration Arch complète, capturée depuis `cogitator` et rejouable sur
une machine neuve.

Deux scripts, deux sens :

| | sens | ce que ça fait |
|---|---|---|
| `./dump.sh` | machine → dépôt | lit la machine et met le dépôt à jour. **Ne modifie rien** sur le système. |
| `./restore.sh` | dépôt → machine | réinstalle paquets, configs, services et thèmes. |

---

## Repartir de zéro

Sur une Arch fraîche (installation `base`, réseau actif, `git` présent) :

```sh
git clone https://github.com/Alexy33/arch_config_arcony.git ~/github/arch_config_arcony
cd ~/github/arch_config_arcony
./restore.sh
```

Le script avance phase par phase et demande confirmation à chacune. Options :

```sh
./restore.sh --list              # lister les phases
./restore.sh --yes               # tout enchaîner sans question
./restore.sh --only home,assets  # ne rejouer que ces phases
./restore.sh --skip repos,aur    # tout sauf ces phases
```

Rien n'est écrasé en silence : tout ce que `restore.sh` remplace part d'abord
dans `~/.arch-config-backup/<horodatage>/`.

### Après la restauration

1. **Déconnexion / reconnexion** — les groupes (`docker`, `vboxusers`) et le
   passage à zsh ne prennent effet qu'à la session suivante.
2. **Premier lancement de zsh** — zinit télécharge ses plugins, laisse-le finir.
3. **Redémarrage** — pour SDDM, Hyprland et les initramfs regénérés.

### Ce que le dépôt ne contient pas

Volontairement exclu : aucun secret ne doit finir dans un historique git.

| à remettre à la main | où |
|---|---|
| Clés SSH | `~/.ssh` — sans elles, les clones `git@github.com:` de la phase `repos` échouent |
| Clés GPG | `~/.gnupg` |
| Base KeePassXC | le `.kdbx` lui-même (sa configuration, elle, est sauvegardée) |
| Connexions Wi-Fi | `/etc/NetworkManager/system-connections/` |
| Tailscale | `sudo tailscale up` pour ré-authentifier |
| Comptes Steam, Discord | reconnexion normale |

---

## Sauvegarder l'état courant

```sh
cd ~/github/arch_config_arcony && ./dump.sh    # ou simplement : arcony
git add -A && git commit -m "dump $(date +%F)" && git push
```

`./dump.sh --list` montre ce qui serait capturé sans rien écrire.

Le dump est un **miroir** : ce que tu supprimes de ta machine disparaît du
dépôt au dump suivant. Pour étendre la capture, il suffit d'ajouter une entrée
aux tableaux en haut de `dump.sh` (`CONFIG_DIRS`, `ETC_FILES`, …).

---

## Ce qui est capturé

```
manifests/    paquets (dépôts + AUR), flatpak, cargo, pipx, npm, pip,
              services systemd, groupes, carte des symlinks, dépôts ~/github
home/
  root/       ~/.zshrc, ~/.bashrc, ~/.gitconfig, …
  dotfiles/   ~/dotfiles — ML4W personnalisé, source de ~/.config/{hypr,waybar,rofi,…}
  my_dotfiles/~/my_dotfiles — fastfetch, ghostty, lazyvim, starship, thème GRUB
  config/     répertoires réels de ~/.config (btop, mako, lazygit, units user…)
  local-bin/  scripts personnels de ~/.local/bin
system/       /etc (pacman.conf, mkinitcpio, grub, sddm, tlp, locale, clavier…)
              et /usr/local/bin/arch-autoupdate
assets/       fonds d'écran, thème SDDM `sequoia`, thèmes GRUB minegrub
```

### Le câblage des configs

`~/.config` n'est pas un répertoire plat : la plupart des entrées sont des
**symlinks** vers `~/dotfiles` ou `~/my_dotfiles`. `dump.sh` enregistre cette
carte dans `manifests/symlinks.txt` et `restore.sh` la rejoue à l'identique, ce
qui garde le fonctionnement actuel : éditer `~/.config/hypr/hyprland.conf`
modifie bien `~/dotfiles/…`, que le dump suivant récupère.

`~/my_dotfiles` a été **absorbé** ici : ce dépôt est désormais la source de
vérité. L'ancien dépôt `YetAnotherMechanicusEnjoyer/dotfiles` n'est plus
synchronisé.

### ML4W

La phase `aur` installe le paquet `ml4w-hyprland` et la phase `flatpak` ses
applications (`com.ml4w.settings`, `sidebar`, `welcome`…). L'installateur ML4W
n'est **pas** lancé : il écraserait `~/dotfiles` avec la version amont. C'est la
copie personnalisée du dépôt qui est déployée.

---

## Mise à jour automatique au démarrage

`arch-autoupdate.timer` lance `pacman -Syu --noconfirm` **3 minutes après chaque
démarrage**, puis une fois par jour si la machine reste allumée.

```sh
systemctl list-timers arch-autoupdate.timer   # prochain déclenchement
journalctl -u arch-autoupdate.service         # ce qui s'est passé  (alias : update-log)
sudo systemctl disable --now arch-autoupdate.timer   # arrêter
```

Le script (`system/usr/local/bin/arch-autoupdate`) rafraîchit d'abord
`archlinux-keyring`, s'abstient si un `db.lck` traîne, signale un noyau mis à
jour nécessitant un redémarrage, et nettoie les orphelins.

> **À savoir.** Une mise à jour Arch non supervisée peut casser le système :
> certaines versions demandent une intervention manuelle annoncée sur
> [archlinux.org](https://archlinux.org/news/), et après une mise à jour du
> noyau les modules pas encore chargés deviennent introuvables jusqu'au
> redémarrage. Jette un œil à `update-log` de temps en temps.
>
> **L'AUR reste manuel** : `yay` refuse de tourner en root, et une compilation
> AUR ratée sans personne devant l'écran laisse un paquet à moitié installé.
> Utilise l'alias `maj` (`yay -Syu`).

---

## La machine de référence

| | |
|---|---|
| Hôte | `cogitator` |
| CPU / GPU | i5-12450HX · Intel UHD + Arc A530M |
| Démarrage | UEFI + GRUB, noyaux `linux` et `linux-lts` |
| Session | SDDM (thème `sequoia`) → Hyprland via ML4W |
| Shell | zsh + zinit + starship |
| Locale | `en_US.UTF-8`, clavier `fr`, `Europe/Paris` |

`manifests/system-info.txt` contient ces valeurs régénérées à chaque dump.
