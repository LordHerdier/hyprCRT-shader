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
# Usage: toggle.sh [--no-reload] [preset]
#   With no argument, toggles crt.frag. With a preset name (subtle,
#   trinitron, arcade, green, amber -- see presets/), toggles that one;
#   asking for a preset while a different one is active switches to it
#   rather than turning the shader off.
#
#   Turning the shader off also runs `hyprctl reload`: flipping
#   debug:damage_tracking back at runtime can leave artifacts on screen,
#   and a reload clears them. --no-reload skips that. Note the reload
#   re-reads your config, so it also discards any other runtime-only
#   changes made through hyprctl.
#
# Requires: hyprctl (comes with Hyprland), jq.
#
# Uses `hyprctl eval` rather than `hyprctl keyword`. The two are not
# interchangeable: `keyword` writes through the config file's own
# parser, and as of Hyprland 0.49 that fails outright --
# "keyword can't work with non-legacy parsers. Use eval." -- the moment
# your hyprland.conf is written in Lua instead of hyprlang. `eval` runs
# Lua against the live config state directly (the same `hl.config` call
# a Lua hyprland.conf would use itself), so it works unconditionally,
# whichever language parsed your config at startup.

set -euo pipefail

reload=1
args=()
for arg in "$@"; do
    case "$arg" in
        --no-reload) reload=0 ;;
        *)           args+=("$arg") ;;
    esac
done
set -- ${args[@]+"${args[@]}"}

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
shader="$dir/crt.frag"
if [ $# -ge 1 ]; then
    shader="$dir/presets/$1.frag"
fi

if [ ! -f "$shader" ]; then
    echo "toggle.sh: no such shader: $shader" >&2
    exit 1
fi

current="$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')"

disabling=0
if [ "$current" = "$shader" ]; then
    disabling=1
    code='hl.config({decoration = {screen_shader = ""}, debug = {damage_tracking = 2}})'
else
    code="hl.config({decoration = {screen_shader = [[${shader}]]}, debug = {damage_tracking = 0}})"
fi

result="$(hyprctl eval "$code")"
if [ "$result" != "ok" ]; then
    echo "toggle.sh: hyprctl eval failed: $result" >&2
    exit 1
fi

# Only on the way off: switching presets keeps damage tracking at 0, so
# nothing changes that could artifact.
if [ "$disabling" = 1 ] && [ "$reload" = 1 ]; then
    hyprctl reload >/dev/null
fi
