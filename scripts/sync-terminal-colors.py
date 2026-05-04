#!/usr/bin/env python3
"""
sync-terminal-colors.py — keep VS Code & Cursor terminal palettes in sync
with the iTerm2 color preset checked into this repo.

Reads:  iterm2/flat-colors.itermcolors
Writes: vscode/settings.json and cursor/settings.json
        (replaces the contents of `workbench.colorCustomizations` only;
         all other settings are left untouched)

Usage:
    ./scripts/sync-terminal-colors.py             # default paths
    ./scripts/sync-terminal-colors.py --check     # exit 1 if drift exists

Run this after re-exporting flat-colors.itermcolors from iTerm2's
"Settings → Profiles → Colors → Color Presets… → Export…" so the editor
terminals stay visually identical to iTerm2.

This script is intentionally dependency-free — only Python stdlib is used.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ITERM_PRESET = REPO_ROOT / "iterm2" / "flat-colors.itermcolors"
TARGETS = [
    REPO_ROOT / "vscode" / "settings.json",
    REPO_ROOT / "cursor" / "settings.json",
]

# Mapping: VS Code color customization key -> iTerm2 preset key.
# The order here defines the order keys are written in settings.json.
KEY_MAP = [
    ("terminal.background",          "Background Color"),
    ("terminal.foreground",          "Foreground Color"),
    ("terminal.ansiBlack",           "Ansi 0 Color"),
    ("terminal.ansiRed",             "Ansi 1 Color"),
    ("terminal.ansiGreen",           "Ansi 2 Color"),
    ("terminal.ansiYellow",          "Ansi 3 Color"),
    ("terminal.ansiBlue",            "Ansi 4 Color"),
    ("terminal.ansiMagenta",         "Ansi 5 Color"),
    ("terminal.ansiCyan",            "Ansi 6 Color"),
    ("terminal.ansiWhite",           "Ansi 7 Color"),
    ("terminal.ansiBrightBlack",     "Ansi 8 Color"),
    ("terminal.ansiBrightRed",       "Ansi 9 Color"),
    ("terminal.ansiBrightGreen",     "Ansi 10 Color"),
    ("terminal.ansiBrightYellow",    "Ansi 11 Color"),
    ("terminal.ansiBrightBlue",      "Ansi 12 Color"),
    ("terminal.ansiBrightMagenta",   "Ansi 13 Color"),
    ("terminal.ansiBrightCyan",      "Ansi 14 Color"),
    ("terminal.ansiBrightWhite",     "Ansi 15 Color"),
    ("terminal.selectionBackground", "Selection Color"),
    ("terminalCursor.foreground",    "Cursor Color"),
    ("terminalCursor.background",    "Cursor Text Color"),
]


def hex_of(component: dict) -> str:
    r = round(component["Red Component"]   * 255)
    g = round(component["Green Component"] * 255)
    b = round(component["Blue Component"]  * 255)
    return f"#{r:02x}{g:02x}{b:02x}"


def build_palette(preset_path: Path) -> dict[str, str]:
    with preset_path.open("rb") as f:
        preset = plistlib.load(f)
    palette: dict[str, str] = {}
    for vsc_key, iterm_key in KEY_MAP:
        if iterm_key not in preset:
            print(f"warning: '{iterm_key}' missing from {preset_path.name}",
                  file=sys.stderr)
            continue
        palette[vsc_key] = hex_of(preset[iterm_key])
    return palette


def replace_color_block(text: str, palette: dict[str, str]) -> str:
    """
    Replace the value of `workbench.colorCustomizations` in a settings.json
    file. Uses regex (not json.loads) so we don't strip JSONC comments or
    reformat the rest of the file.
    """
    # Find: "workbench.colorCustomizations": { ... }
    # Match across multiple lines, accounting for nested braces (one level
    # deep is enough for this key — its value is a flat object).
    pattern = re.compile(
        r'("workbench\.colorCustomizations"\s*:\s*)\{[^{}]*\}',
        re.DOTALL,
    )
    if not pattern.search(text):
        raise SystemExit(
            "error: 'workbench.colorCustomizations' block not found. "
            "Add an empty `\"workbench.colorCustomizations\": {}` to the "
            "settings file first, then re-run."
        )

    # Build a nicely-aligned replacement block. Compute padding so the hex
    # values line up the way they do in the existing file.
    longest = max(len(k) for k in palette)
    lines = ["{"]
    for k, v in palette.items():
        pad = " " * (longest - len(k))
        lines.append(f'    "{k}":{pad}  "{v}",')
    # Drop trailing comma on last entry
    lines[-1] = lines[-1].rstrip(",")
    lines.append("  }")
    block = "\n".join(lines)

    return pattern.sub(lambda m: m.group(1) + block, text)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--check", action="store_true",
                    help="exit 1 if any target file would be modified")
    args = ap.parse_args()

    if not ITERM_PRESET.exists():
        print(f"error: {ITERM_PRESET} not found", file=sys.stderr)
        return 2

    palette = build_palette(ITERM_PRESET)
    drift = False

    for target in TARGETS:
        if not target.exists():
            print(f"  skip: {target} (not found)")
            continue
        original = target.read_text()
        updated = replace_color_block(original, palette)
        if original == updated:
            print(f"  ok:   {target.relative_to(REPO_ROOT)} already in sync")
            continue
        drift = True
        if args.check:
            print(f"  drift: {target.relative_to(REPO_ROOT)} would be updated")
        else:
            target.write_text(updated)
            print(f"  wrote: {target.relative_to(REPO_ROOT)}")

    if args.check and drift:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
