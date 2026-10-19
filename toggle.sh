#!/usr/bin/env bash
# Toggle the CRT shader on and off for the running Hyprland session.
#
# Deliberately off at login and off again after any compositor restart:
# a shader that fails to compile leaves a black screen, and recovering
# from that means blind-typing hyprctl. This script is the opt-in.
#
# debug:damage_tracking rides along with the shader, and has to — see
# the comment in crt.frag. It's only ever 0 while the shader is on, and
# restored to 2 (Hyprland's default, "full") the moment it's off, so the
# cost is scoped to a session that actually enables the shader.
#
# Requires: hyprctl (comes with Hyprland), jq.

set -euo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
shader="$dir/crt.frag"

if [ ! -f "$shader" ]; then
    echo "toggle.sh: expected crt.frag next to this script at $shader" >&2
    exit 1
fi

current="$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')"

if [ "$current" = "$shader" ]; then
    hyprctl keyword decoration:screen_shader ""
    hyprctl keyword debug:damage_tracking 2
else
    hyprctl keyword decoration:screen_shader "$shader"
    hyprctl keyword debug:damage_tracking 0
fi
