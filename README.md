# dotfiles

Personal macOS dotfiles, kept in sync between an Intel MacBook Pro and an
Apple Silicon MacBook Air.

Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles),
but reorganized around Zsh + Oh My Zsh and a symlink-based bootstrap so edits
in `~` flow back to the repo automatically.

## What's in here

```
dotfiles/
├── bootstrap.sh         # Symlinks files from this repo into your $HOME
├── install.sh           # One-shot setup for a fresh Mac (brew, omz, plugins, bootstrap)
├── uninstall.sh         # Restores the backups bootstrap.sh made
├── Brewfile             # Formulae, casks, and Mac App Store apps (brew bundle)
├── .macos               # macOS system defaults (Finder, Dock, trackpad, etc.)
├── shell/               # .zshrc, .zprofile, .aliases, .functions, .exports
├── home/                # misc home-dir dotfiles (.p10k.zsh, .inputrc, etc.)
├── git/                 # .gitconfig, .gitignore_global
├── iterm2/              # iTerm2 exported preferences (com.googlecode.iterm2.plist)
├── vscode/              # settings.json, keybindings.json, extensions.txt
└── cursor/              # settings.json, keybindings.json, extensions.txt
```

## Quick start (fresh Mac)

```sh
# 1. Install Xcode CLI tools (needed for git + brew)
xcode-select --install

# 2. Clone the repo
git clone https://github.com/<your-username>/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Run the one-shot installer
./install.sh
```

`install.sh` will:

1. Install Homebrew (correct prefix for Intel vs Apple Silicon, auto-detected).
2. Run `brew bundle` against the `Brewfile`.
3. Install Oh My Zsh, the two plugins it expects (`zsh-autosuggestions`,
   `zsh-syntax-highlighting`), and the **Powerlevel10k** theme.
4. Run `./bootstrap.sh` to symlink configs into `~` (including
   `~/.p10k.zsh`, so the prompt is preconfigured — no `p10k configure`
   wizard on first launch).
5. Optionally apply `./.macos` system defaults (you'll be asked).
6. Print next-steps for iTerm2 and VS Code / Cursor.

## Updating an already-set-up machine

```sh
cd ~/.dotfiles
git pull
./bootstrap.sh        # re-symlink in case anything new was added
brew bundle --file=./Brewfile
```

Because `bootstrap.sh` creates **symlinks**, editing `~/.zshrc` directly is
the same as editing `shell/.zshrc` in the repo — just `cd ~/.dotfiles`,
commit, and push.

## Multi-machine notes

- A single `Brewfile` is shared; Homebrew handles arch-specific bottles
  transparently. The shell setup auto-detects `/usr/local/bin/brew` (Intel)
  vs `/opt/homebrew/bin/brew` (Apple Silicon).
- Anything machine-specific (work env vars, hostname-conditional paths, etc.)
  lives in `~/.zshrc.local`, which is sourced by `.zshrc` if present and is
  **gitignored**.
- The same pattern works for git: put per-machine identity in
  `~/.gitconfig.local` and it'll be included by the shared `.gitconfig`.

## iTerm2

Open iTerm2 → **Preferences → General → Preferences** and check
"Load preferences from a custom folder or URL", then point it at
`~/.dotfiles/iterm2`. iTerm2 will read `com.googlecode.iterm2.plist`
from there and keep it in sync across machines.

### Powerlevel10k font

The prompt uses Powerlevel10k, which renders its icons with a Nerd
Font. The Brewfile already installs **Meslo LG Nerd Font** (cask
`font-meslo-lg-nerd-font`), so on a fresh install you just need to
*select* it in iTerm2:

**Settings → Profiles → Text → Font → "MesloLGS NF"**

If the prompt shows boxes (`▯`) instead of arrows, branch icons, etc.,
the font isn't being picked up — re-check that the cask installed and
that the right font is selected. The same applies to the integrated
terminals in VS Code and Cursor; set
`"terminal.integrated.fontFamily": "MesloLGS NF"` in their
`settings.json` if needed.

The wizard-generated config lives at `home/p10k.zsh` in this repo and
is symlinked to `~/.p10k.zsh` by `bootstrap.sh`. To regenerate it on a
machine, run `p10k configure`, then commit the updated file back to the
repo.

## VS Code / Cursor

After running `install.sh`:

```sh
# Install the extensions listed in the repo
xargs -L1 code   install --extension < vscode/extensions.txt
xargs -L1 cursor install --extension < cursor/extensions.txt
```

The `settings.json` and `keybindings.json` files are symlinked into
`~/Library/Application Support/Code/User/` and
`~/Library/Application Support/Cursor/User/` by `bootstrap.sh`.

### Integrated terminal colors

The integrated terminals in VS Code and Cursor are themed to match the
iTerm2 "Flat" preset (see `iterm2/flat-colors.itermcolors`). The palette
lives inline as hex values under `workbench.colorCustomizations` in each
editor's `settings.json`, so it's applied automatically the first time
`bootstrap.sh` symlinks those files in — no extra install step.

If you ever change the iTerm2 colors, run
`scripts/sync-terminal-colors.py` to regenerate the editor palettes from
the updated `.itermcolors` file. See `iterm2/README.md` for the full
re-export workflow.

## Git hooks (pre-push secret scan)

`git/gitconfig` sets `core.hooksPath = ~/.dotfiles/git/hooks`, which makes git
look for hooks in this repo for **every** local repository on the machine.
Currently there's one hook:

- **`git/hooks/pre-push`** — runs [gitleaks](https://github.com/gitleaks/gitleaks)
  on the outgoing commit range before each `git push`. Aborts the push if it
  finds anything that looks like a secret (API key, private key, token, etc.).

If gitleaks isn't installed yet on a machine, the hook prints a notice and
exits cleanly so it doesn't block the push.

To bypass for one push: `git push --no-verify`
To disable globally:    `git config --global --unset core.hooksPath`

A repo can override the global hooks path locally (e.g. Husky-managed Node
projects do this automatically), in which case its own hooks run instead.

## Uninstall / rollback

`bootstrap.sh` saves anything it overwrites to `~/.dotfiles-backup-<timestamp>/`.
Run `./uninstall.sh` to remove the symlinks and restore the most recent backup.

## Secrets

Never commit any of these — they're in `.gitignore` already:

- `~/.zshrc.local`, `~/.gitconfig.local`
- `~/.ssh/`, `~/.gnupg/`
- `.env`, `.env.*`, anything matching `*_token`, `*_secret`, `*.pem`, `*.key`
