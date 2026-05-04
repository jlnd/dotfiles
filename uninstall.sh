#!/usr/bin/env bash
# uninstall.sh — remove symlinks created by bootstrap.sh and restore the
# most recent backup folder under $HOME (.dotfiles-backup-*).

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Find newest backup dir
BACKUP_DIR="$(find "$HOME" -maxdepth 1 -type d -name '.dotfiles-backup-*' -print 2>/dev/null \
  | sort | tail -n1)"

if [[ -z "${BACKUP_DIR:-}" ]]; then
  echo "No .dotfiles-backup-* folder found in $HOME — nothing to restore."
  echo "Will still remove any symlinks pointing into $DOTFILES_DIR."
fi

remove_link() {
  local dst="$1"
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$DOTFILES_DIR/"* ]]; then
    rm "$dst"
    echo "  removed symlink: $dst"
  fi
}

restore_backup() {
  local rel="$1"  # path relative to $HOME
  local src="$BACKUP_DIR/$rel"
  local dst="$HOME/$rel"
  if [[ -e "$src" || -L "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
    echo "  restored:        $dst"
  fi
}

# Same list as bootstrap.sh
TARGETS=(
  ".zshrc"
  ".zprofile"
  ".aliases"
  ".exports"
  ".functions"
  ".gitconfig"
  ".gitignore_global"
  ".hushlogin"
  ".inputrc"
  ".curlrc"
  ".wgetrc"
  "Library/Application Support/Code/User/settings.json"
  "Library/Application Support/Code/User/keybindings.json"
  "Library/Application Support/Cursor/User/settings.json"
  "Library/Application Support/Cursor/User/keybindings.json"
)

for rel in "${TARGETS[@]}"; do
  remove_link "$HOME/$rel"
  [[ -n "${BACKUP_DIR:-}" ]] && restore_backup "$rel"
done

if [[ -n "${BACKUP_DIR:-}" ]] && [[ -z "$(find "$BACKUP_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
  rmdir "$BACKUP_DIR"
  echo "Removed empty backup dir: $BACKUP_DIR"
fi

echo "Done."
