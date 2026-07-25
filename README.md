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
└── cursor/              # settings.json, keybindings.json, extensions.txt, mcp.json.example
└── claude/              # Claude Code settings.json (+ settings.local.json.example for docs)


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

`cusor/mcp.json.example` shows the MCP server shape for reference. Keep
your live `~/.cursor/mcp.json` (with real tokens) out of git - see \
[Secrets](#secrets) below

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

## Claude Code

After running `install.sh` (or `./bootstrap.sh` on an existing machine):

- `claude/settings.json` is symlinked to `~/.claude/settings.json`
  (permissions, theme, non-secret Bedrock flags like `CLAUDE_CODE_USE_BEDROCK`
  and `AWS_REGION`). Claude Code reads these at startup — including from the
  desktop app, which does **not** load your shell profile.
- `claude/settings.local.json` is symlinked to `~/.claude/settings.local.json`
  for machine-specific secrets (e.g. `AWS_BEARER_TOKEN_BEDROCK`). The file
  lives in the dotfiles repo on each machine but is **gitignored** — copy
  `claude/settings.local.json.example` on a new machine and fill in your token.
  On first bootstrap, an existing token in `~/.zshrc.local` is migrated
  automatically.
- `~/.claude.json` and everything else under `~/.claude/` (sessions, projects,
  plugins cache) stays **local only** — do not add those to the repo.

Verify Bedrock with `/status` inside Claude Code after a full app restart
(Cmd+Q, then reopen).

## Config map (avoid mixing these up)

| Path | Purpose | Synced? |
|------|---------|---------|
| `~/.dotfiles/cursor/` | Cursor editor UI prefs | Yes (symlinked) |
| `~/.cursor` | Cursor runtime (MCP, extensions, skills, state) | No |
| `~/.dotfiles/claude/settings.json` | Claude Code shared settings | Yes (symlinked) |
| `~/.dotfiles/claude/settings.local.json` | Claude Code secrets (Bedrock token) | Per-machine (gitignored) |
| `~/.claude/` (except the two settings files) | Claude runtime, sessions | No |
| `~/.claude.json` | Claude app/onboarding state | No |
| `~/.codex` | Codex CLI config | No (future optional) |

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
- `~/.cursor/mcp.json` (use `cursor/mcp.json.example` as a template)
- `claude/settings.local.json`, `cursor/mcp.local.json`, `*.local.json`
- `.env`, `.env.*`, anything matching `*_token`, `*_secret`, `*.pem`, `*.key`

Claude Code Bedrock auth: non-secret flags in `claude/settings.json`;
`AWS_BEARER_TOKEN_BEDROCK` in `claude/settings.local.json` (gitignored).
Do not put Bedrock vars in `~/.zshrc.local` — the desktop app won't see them.
