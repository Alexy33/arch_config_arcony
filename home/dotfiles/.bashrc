#    _               _              
#   | |__   __ _ ___| |__  _ __ ___ 
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__ 
# (_)_.__/ \__,_|___/_| |_|_|  \___|
# 
# -----------------------------------------------------
# ML4W bashrc loader
# -----------------------------------------------------

# DON'T CHANGE THIS FILE

# You can define your custom configuration by adding
# files in ~/.config/bashrc 
# or by creating a folder ~/.config/bashrc/custom
# with copies of files from ~/.config/bashrc 
# You can also create a .bashrc_custom file in your home directory
# -----------------------------------------------------

# -----------------------------------------------------
# Load modular configarion
# -----------------------------------------------------

for f in ~/.config/bashrc/*; do 
    if [ ! -d $f ]; then
        c=`echo $f | sed -e "s=.config/bashrc=.config/bashrc/custom="`
        [[ -f $c ]] && source $c || source $f
    fi
done

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

if [ -f ~/.bashrc_custom ]; then
    source ~/.bashrc_custom
fi

# Learning Challenge Manager
export PATH="$PATH:/home/omnimessie/.local/bin"

# Learning Challenge - Fausses erreurs
if [[ -f '/home/omnimessie/.learning_challenge/fake_errors.sh' ]]; then
  bash '/home/omnimessie/.learning_challenge/fake_errors.sh' '43' &
fi

# Learning Challenge - Fausses erreurs
if [[ -f '/home/omnimessie/.learning_challenge/fake_errors.sh' ]]; then
  bash '/home/omnimessie/.learning_challenge/fake_errors.sh' '56' &
fi

# Learning Challenge - Pénalité temporaire
if [[ -f '/home/omnimessie/.learning_challenge/punishment_aliases.sh' ]] && [[ $(date '+%s') -lt $(date -d '$(cat /home/omnimessie/.learning_challenge/punishment_end_time 2>/dev/null || echo "1970-01-01")' '+%s' 2>/dev/null || echo 0) ]]; then
  source '/home/omnimessie/.learning_challenge/punishment_aliases.sh'
  echo '🚫 Mode pénalité actif - Commandes perturbées jusqu'à 2025-08-14 22:40:22'
fi
