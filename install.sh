#!/usr/bin/env bash
# Manual install for anyone not on Nix: copies the shader and the toggle
# script into Hyprland's config directory.
#
# Usage: ./install.sh
# Then add to hyprland.conf (see README.md for the full explanation):
#
#   cursor {
#       no_hardware_cursors = true
#   }
#
#   bind = SUPER, F12, exec, ~/.config/hypr/shaders/toggle.sh

set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/shaders"

mkdir -p "$dest"
install -Dm444 "$dir/crt.frag" "$dest/crt.frag"
for f in "$dir"/presets/*.frag; do
    install -Dm444 "$f" "$dest/presets/$(basename "$f")"
done
install -Dm755 "$dir/toggle.sh" "$dest/toggle.sh"

echo "Installed to $dest"
echo "Bind \"$dest/toggle.sh\" to a key in hyprland.conf to use it — see README.md."
