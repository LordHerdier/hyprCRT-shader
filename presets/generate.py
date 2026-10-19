#!/usr/bin/env python3
"""Regenerate presets/*.frag from crt.frag.

Hyprland loads a single shader file with no #include, so each preset has
to be a complete copy. Rather than hand-maintaining copies that drift,
each one is crt.frag with a handful of `const` values overridden here.
Edit crt.frag or the table below, then re-run:  python3 presets/generate.py
"""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
base = (root / "crt.frag").read_text()

PRESETS = {
    "subtle": ("Barely-there tube: flat glass, faint scanlines, soft mask.", {
        "CURVE": "0.05", "SCAN_DEPTH": "0.30", "MASK_DARK": "0.92",
        "ABERR_PX": "0.5", "VIGNETTE": "0.03", "BRIGHT_BOOST": "1.05",
    }),
    "trinitron": ("Sharp PVM-style monitor: near-flat, tight fine scanlines, crisp grille.", {
        "CURVE": "0.04", "SCAN_PERIOD": "4.0", "SCAN_DEPTH": "0.55",
        "BEAM_MIN": "0.25", "BEAM_MAX": "0.45", "MASK_DARK": "0.70",
        "ABERR_PX": "0.4", "VIGNETTE": "0.03", "BRIGHT_BOOST": "1.25",
    }),
    "arcade": ("Worn arcade cabinet: heavy curve, deep scanlines, slot mask, glow.", {
        "CURVE": "0.22", "CORNER_SIZE": "0.02", "SCAN_DEPTH": "0.90",
        "SLOT_H": "4.0", "MASK_DARK": "0.65", "ABERR_PX": "1.8",
        "VIGNETTE": "0.12", "BRIGHT_BOOST": "1.35",
        "HALATION": "0.35", "DIFFUSION": "0.05",
    }),
    "green": ("Green-phosphor terminal: monochrome, strong glow, no convergence error.", {
        "MONO": "1.0", "TINT": "vec3(0.10, 1.00, 0.25)", "CURVE": "0.18",
        "SCAN_DEPTH": "0.60", "MASK_DARK": "0.90", "ABERR_PX": "0.0",
        "VIGNETTE": "0.10", "BRIGHT_BOOST": "1.35",
        "HALATION": "0.50", "DIFFUSION": "0.08",
    }),
    "amber": ("Amber-phosphor terminal: monochrome, warm glow, no convergence error.", {
        "MONO": "1.0", "TINT": "vec3(1.00, 0.45, 0.04)", "CURVE": "0.18",
        "SCAN_DEPTH": "0.60", "MASK_DARK": "0.90", "ABERR_PX": "0.0",
        "VIGNETTE": "0.10", "BRIGHT_BOOST": "1.35",
        "HALATION": "0.50", "DIFFUSION": "0.08",
    }),
}

for name, (desc, overrides) in PRESETS.items():
    src = base
    for const, value in overrides.items():
        # `const <type> NAME = <value>;` -- keep type, alignment, comment.
        pat = re.compile(rf"^(const \w+\s+{const}\s*=\s*)[^;]+;", re.M)
        src, n = pat.subn(lambda m: f"{m.group(1)}{value};", src)
        if n != 1:
            sys.exit(f"{name}: {const} matched {n} times in crt.frag")
    head, rest = src.split("\n", 1)
    banner = (f"\n// Preset: {name} -- {desc}\n"
              "// Generated from crt.frag by presets/generate.py; edit that, not this.\n")
    (root / "presets" / f"{name}.frag").write_text(head + "\n" + banner + rest)
    print(f"wrote presets/{name}.frag")
