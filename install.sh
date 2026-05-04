#!/usr/bin/env bash
# install.sh — one-shot setup for a fresh Mac.
#
# Steps:
#   1. Install Homebrew (correct prefix for Intel vs Apple Silicon)
#   2. brew bundle (Brewfile)
#   3. Install Oh My Zsh + zsh-autosuggestions + zsh-syntax-highlighting
#      + Powerlevel10k theme
#   4. Run bootstrap.sh to symlink configs into ~
#   5. Optionally apply ./macos.sh

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ask_yn() {
  # ask_yn "Question?" -> returns 0 for yes, 1 for no. Default = no on enter.
  read -r -p "$1 [y/N] " reply || true
  [[ "$reply" =~ ^[Yy]$ ]]
}

bold() { printf "\n\033[1m==> %s\033[0m\n" "$*"; }

# ---------- 1. Homebrew ------------------------------------------------------
bold "Checking for Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in this script regardless of arch
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Using Homebrew at: $(command -v brew)"

# ---------- 2. brew bundle ---------------------------------------------------
bold "Running brew bundle"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# ---------- 3. Oh My Zsh -----------------------------------------------------
bold "Setting up Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions / zsh-syntax-highlighting:
# These are also in the Brewfile (faster + auto-updated by brew). We clone
# them into Oh My Zsh's custom dir so the `plugins=(...)` line in .zshrc
# picks them up the standard Oh My Zsh way.
clone_omz_plugin() {
  local name="$1" url="$2"
  if [[ ! -d "$ZSH_CUSTOM/plugins/$name" ]]; then
    git clone --depth=1 "$url" "$ZSH_CUSTOM/plugins/$name"
  else
    echo "Plugin $name already present."
  fi
}
clone_omz_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_omz_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# Powerlevel10k theme — referenced as ZSH_THEME in shell/zshrc.
# Cloned into Oh My Zsh's custom themes dir; ~/.p10k.zsh (symlinked by
# bootstrap.sh from home/p10k.zsh) holds the wizard-generated config so
# the prompt is preconfigured on first launch — no `p10k configure` run
# required. The Meslo Nerd Font that p10k expects is already installed by
# the Brewfile (cask "font-meslo-lg-nerd-font"); just point iTerm2 at it
# (Settings → Profiles → Text → Font: "MesloLGS NF").
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
else
  echo "Theme powerlevel10k already present."
fi

# ---------- 4. Symlink dotfiles ---------------------------------------------
bold "Linking dotfiles into your home directory"
"$DOTFILES_DIR/bootstrap.sh"

# ---------- 5. macOS defaults (optional) ------------------------------------
if ask_yn "Apply macOS system defaults from ./macos.sh?"; then
  "$DOTFILES_DIR/macos.sh"
fi

# ---------- 6. Make Zsh the default shell -----------------------------------
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [[ -x "$BREW_ZSH" ]] && [[ "$SHELL" != "$BREW_ZSH" ]]; then
  if ! grep -q "^${BREW_ZSH}\$" /etc/shells; then
    echo "Adding $BREW_ZSH to /etc/shells (sudo required)"
    echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  if ask_yn "Set $BREW_ZSH as your default login shell?"; then
    chsh -s "$BREW_ZSH"
  fi
fi

cat <<'EOF'

All done. Next steps:

  1. Quit and reopen iTerm2 (and your terminal in VS Code / Cursor).
  2. Point iTerm2 at the prefs folder: Settings → General → Settings →
     "Load settings from a custom folder or URL" → choose ~/.dotfiles/iterm2
  3. Set the iTerm2 font for the Powerlevel10k prompt icons:
     Settings → Profiles → Text → Font → "MesloLGS NF"
     (installed via the Brewfile — cask "font-meslo-lg-nerd-font").
     Do the same in VS Code / Cursor: set "terminal.integrated.fontFamily"
     to "MesloLGS NF" if the prompt glyphs render as boxes.
  4. Install your editor extensions:
       xargs -L1 code   --install-extension < ~/.dotfiles/vscode/extensions.txt
       xargs -L1 cursor --install-extension < ~/.dotfiles/cursor/extensions.txt
  5. Edit ~/.gitconfig.local to set your name and email if needed.

EOF
