#!/usr/bin/env bash
# bootstrap.sh — symlink dotfiles from this repo into $HOME.
#
# Anything already at the destination path is moved into a timestamped
# backup folder (~/.dotfiles-backup-YYYYmmddHHMMSS) so you can roll back
# with `uninstall.sh`.
#
# Re-running is safe: existing symlinks that already point at this repo
# are left alone.

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# Each line: <source path relative to repo>  <destination path relative to $HOME>
LINKS=(
  "shell/zshrc           .zshrc"
  "shell/zprofile        .zprofile"
  "shell/aliases         .aliases"
  "shell/exports         .exports"
  "shell/functions       .functions"
  "git/gitconfig         .gitconfig"
  "git/gitignore_global  .gitignore_global"
  "home/hushlogin        .hushlogin"
  "home/inputrc          .inputrc"
  "home/curlrc           .curlrc"
  "home/wgetrc           .wgetrc"
  "home/p10k.zsh         .p10k.zsh"
)

# VS Code / Cursor live in Library/Application Support, handled separately below.

mkdir -p "$BACKUP_DIR"

link_one() {
  local src="$DOTFILES_DIR/$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "  skip: $1 (not found in repo)"
    return
  fi

  # If destination is already a symlink to the right place, do nothing.
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok:   $dst -> $src"
    return
  fi

  # If something exists at dst (file/dir/other symlink), back it up.
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$(dirname "$BACKUP_DIR/${dst#"$HOME"/}")"
    mv "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
    echo "  backup: $dst -> $BACKUP_DIR/${dst#"$HOME"/}"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link:  $dst -> $src"
}

echo "Linking dotfiles from $DOTFILES_DIR into $HOME"
echo "Existing files (if any) will be backed up to $BACKUP_DIR"
echo

for entry in "${LINKS[@]}"; do
  # shellcheck disable=SC2086
  set -- $entry
  link_one "$1" "$HOME/$2"
done

# ---------- VS Code ----------------------------------------------------------
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$HOME/Library/Application Support/Code" ]]; then
  mkdir -p "$VSCODE_USER_DIR"
  link_one "vscode/settings.json"    "$VSCODE_USER_DIR/settings.json"
  link_one "vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
fi

# ---------- Cursor -----------------------------------------------------------
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$HOME/Library/Application Support/Cursor" ]]; then
  mkdir -p "$CURSOR_USER_DIR"
  link_one "cursor/settings.json"    "$CURSOR_USER_DIR/settings.json"
  link_one "cursor/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
fi

# ---------- Empty backup dir → remove it ------------------------------------
if [[ -d "$BACKUP_DIR" ]] && [[ -z "$(find "$BACKUP_DIR" -mindepth 1 -print -quit)" ]]; then
  rmdir "$BACKUP_DIR"
fi

# ---------- Stub out machine-local files if missing -------------------------
[[ -e "$HOME/.zshrc.local" ]]    || { echo "# machine-local zsh overrides — NOT in git" > "$HOME/.zshrc.local"; }
[[ -e "$HOME/.gitconfig.local" ]] || cat > "$HOME/.gitconfig.local" <<'EOF'
# machine-local git overrides — NOT in git
# Fill these in (and add anything else machine-specific, like signingkey).
[user]
	name  = YOUR NAME
	email = you@example.com
EOF

echo
echo "Done. Open a new shell (or run: source ~/.zshrc) to pick up changes."
