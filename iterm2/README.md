# iTerm2 preferences

iTerm2's preferences live in `com.googlecode.iterm2.plist`. The cleanest
way to keep them in sync between machines is to let iTerm2 itself read
and write the plist directly from this folder.

## One-time setup on each machine

1. Open iTerm2.
2. **Preferences → General → Preferences**.
3. Check **Load preferences from a custom folder or URL**.
4. Click **Browse…** and choose `~/.dotfiles/iterm2`.
5. Set **Save changes** to **Automatic** (or "When Quitting").

iTerm2 will now read its config from this folder and write changes back
here. Commit and push from one machine, pull on the other.

## Exporting current preferences (first time only)

If this folder is empty and you already have iTerm2 set up the way you
like it on one machine, do this on that machine first:

```sh
defaults export com.googlecode.iterm2 ~/.dotfiles/iterm2/com.googlecode.iterm2.plist
```

Then commit:

```sh
cd ~/.dotfiles
git add iterm2/com.googlecode.iterm2.plist
git commit -m "iterm2: snapshot current preferences"
git push
```

After that, follow the "One-time setup" steps above on each machine.

## Color scheme: `flat-colors.itermcolors`

`flat-colors.itermcolors` is a portable export of the active iTerm2
color preset. Because the synced `com.googlecode.iterm2.plist` already
carries it, you don't need this file in normal use — it's there for two
reasons:

- **Portability:** if you ever set up iTerm2 on a machine that *isn't*
  using the synced prefs folder, double-click the file (or run
  `open flat-colors.itermcolors`) and pick it from
  **Settings → Profiles → Colors → Color Presets…**
- **Source of truth for the editor terminals:** the same palette is
  mirrored as hex values inside `vscode/settings.json` and
  `cursor/settings.json` under `workbench.colorCustomizations`, so the
  integrated terminals in VS Code and Cursor look the same as iTerm2.

When you tweak the iTerm2 colors, re-sync the editors with:

```sh
# 1. Export the preset from iTerm2:
#    Settings → Profiles → Colors → Color Presets… → Export…
#    Save as ~/.dotfiles/iterm2/flat-colors.itermcolors (overwrite).
# 2. Regenerate the editor palettes from that file:
~/.dotfiles/scripts/sync-terminal-colors.py
# 3. Commit the diff in iterm2/, vscode/, and cursor/.
```

`scripts/sync-terminal-colors.py --check` is also CI-friendly: it
returns a non-zero exit code if the editor palettes have drifted away
from the iTerm2 preset.
