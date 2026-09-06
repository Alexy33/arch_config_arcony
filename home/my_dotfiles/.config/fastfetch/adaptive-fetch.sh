#!/bin/bash
cols=$(tput cols)

if [ "$cols" -lt 130 ]; then
  fastfetch --config ~/.config/fastfetch/config-small.jsonc
else
  fastfetch --config ~/.config/fastfetch/config-large.jsonc
fi
