#!/usr/bin/env bash
# compare.sh — diff every file this repo would manage against the live
# version in your $HOME, so you can spot existing local customizations
# worth pulling into the repo.
#
# Read-only: never modifies anything. Writes a report to ./compare-report.txt
# (gitignored) that you can scroll through or share.

set -u

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT="$DOTFILES_DIR/compare-report.txt"
: > "$REPORT"

# Flat array: <repo path> <home path> <repo path> <home path> ...
# Iterated two-at-a-time so paths can safely contain spaces.
PAIRS=(
  "shell/zshrc"            ".zshrc"
  "shell/zprofile"         ".zprofile"
  "shell/aliases"          ".aliases"
  "shell/exports"          ".exports"
  "shell/functions"        ".functions"
  "git/gitconfig"          ".gitconfig"
  "git/gitignore_global"   ".gitignore_global"
  "home/hushlogin"         ".hushlogin"
  "home/inputrc"           ".inputrc"
  "home/curlrc"            ".curlrc"
  "home/wgetrc"            ".wgetrc"
  "home/p10k.zsh"          ".p10k.zsh"
  "vscode/settings.json"    "Library/Application Support/Code/User/settings.json"
  "vscode/keybindings.json" "Library/Application Support/Code/User/keybindings.json"
  "cursor/settings.json"    "Library/Application Support/Cursor/User/settings.json"
  "cursor/keybindings.json" "Library/Application Support/Cursor/User/keybindings.json"
)

# ANSI colors (only if stdout is a tty)
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'
  YEL=$'\033[33m'; BLU=$'\033[34m'; RST=$'\033[0m'
else
  BOLD=""; DIM=""; GRN=""; YEL=""; BLU=""; RST=""
fi

# Print to both stdout and the report file
out() { printf "%s\n" "$*" | tee -a "$REPORT" >/dev/null; printf "%s\n" "$*"; }
header() { out "${BOLD}${BLU}== $* ==${RST}"; }

resolve_real() {
  # If the home file is a symlink into this repo, treat it as managed (skip diff).
  local p="$1"
  if [[ -L "$p" ]]; then
    local target
    target="$(readlink "$p")"
    [[ "$target" == "$DOTFILES_DIR/"* ]] && return 0
  fi
  return 1
}

compare_pair() {
  local repo_rel="$1" home_rel="$2"
  local repo_path="$DOTFILES_DIR/$repo_rel"
  local home_path="$HOME/$home_rel"

  out ""
  header "$home_rel  vs  $repo_rel"

  if [[ ! -e "$home_path" && ! -L "$home_path" ]]; then
    out "${DIM}  (no file at $home_path — repo version will be the source of truth)${RST}"
    return
  fi

  if resolve_real "$home_path"; then
    out "${GRN}  already a symlink into the repo — bootstrap.sh has run; nothing to compare${RST}"
    return
  fi

  if [[ ! -e "$repo_path" ]]; then
    out "${YEL}  (no file at $repo_path — your local version is unique)${RST}"
    out "  --- live ($home_path) ---"
    sed 's/^/    /' "$home_path" | tee -a "$REPORT"
    return
  fi

  if cmp -s "$repo_path" "$home_path"; then
    out "${GRN}  identical — nothing to merge${RST}"
    return
  fi

  out "${YEL}  files differ — diff (repo → live):${RST}"
  diff -u --label "repo:$repo_rel" --label "live:~/$home_rel" \
    "$repo_path" "$home_path" \
    | sed 's/^/    /' \
    | tee -a "$REPORT"
}

###############################################################################
# Plain dotfiles
###############################################################################
for ((i=0; i<${#PAIRS[@]}; i+=2)); do
  compare_pair "${PAIRS[i]}" "${PAIRS[i+1]}"
done

###############################################################################
# VS Code extensions
###############################################################################
out ""
header "VS Code extensions"
if command -v code >/dev/null 2>&1; then
  live="$(code --list-extensions 2>/dev/null | sort)"
  repo="$(grep -v '^\s*#' "$DOTFILES_DIR/vscode/extensions.txt" | grep -v '^\s*$' | sort)"
  only_live="$(comm -23 <(echo "$live") <(echo "$repo"))"
  only_repo="$(comm -13 <(echo "$live") <(echo "$repo"))"
  if [[ -z "$only_live" && -z "$only_repo" ]]; then
    out "${GRN}  in sync${RST}"
  else
    [[ -n "$only_live" ]] && out "${YEL}  installed locally but NOT in repo (consider adding):${RST}" \
      && echo "$only_live" | sed 's/^/    + /' | tee -a "$REPORT"
    [[ -n "$only_repo" ]] && out "${YEL}  in repo but NOT installed locally:${RST}" \
      && echo "$only_repo" | sed 's/^/    - /' | tee -a "$REPORT"
  fi
else
  out "${DIM}  (code CLI not on PATH — open VS Code → cmd+shift+p → 'Install code command')${RST}"
fi

###############################################################################
# Cursor extensions
###############################################################################
out ""
header "Cursor extensions"
if command -v cursor >/dev/null 2>&1; then
  live="$(cursor --list-extensions 2>/dev/null | sort)"
  repo="$(grep -v '^\s*#' "$DOTFILES_DIR/cursor/extensions.txt" | grep -v '^\s*$' | sort)"
  only_live="$(comm -23 <(echo "$live") <(echo "$repo"))"
  only_repo="$(comm -13 <(echo "$live") <(echo "$repo"))"
  if [[ -z "$only_live" && -z "$only_repo" ]]; then
    out "${GRN}  in sync${RST}"
  else
    [[ -n "$only_live" ]] && out "${YEL}  installed locally but NOT in repo (consider adding):${RST}" \
      && echo "$only_live" | sed 's/^/    + /' | tee -a "$REPORT"
    [[ -n "$only_repo" ]] && out "${YEL}  in repo but NOT installed locally:${RST}" \
      && echo "$only_repo" | sed 's/^/    - /' | tee -a "$REPORT"
  fi
else
  out "${DIM}  (cursor CLI not on PATH — open Cursor → cmd+shift+p → 'Install cursor command')${RST}"
fi

###############################################################################
# Brewfile
###############################################################################
out ""
header "Brewfile (formulae / casks / mas)"
if command -v brew >/dev/null 2>&1; then
  tmpfile="$(mktemp)"
  brew bundle dump --file="$tmpfile" --force --describe 2>/dev/null
  live_norm="$(grep -E '^(brew|cask|mas|tap) ' "$tmpfile"      | sed 's/, *$//' | sort)"
  repo_norm="$(grep -E '^(brew|cask|mas|tap) ' "$DOTFILES_DIR/Brewfile" | sed 's/#.*//; s/[[:space:]]*$//' | sort)"
  only_live="$(comm -23 <(echo "$live_norm") <(echo "$repo_norm"))"
  only_repo="$(comm -13 <(echo "$live_norm") <(echo "$repo_norm"))"
  rm -f "$tmpfile"
  if [[ -z "$only_live" && -z "$only_repo" ]]; then
    out "${GRN}  in sync${RST}"
  else
    [[ -n "$only_live" ]] && out "${YEL}  installed locally but NOT in Brewfile (consider adding):${RST}" \
      && echo "$only_live" | sed 's/^/    + /' | tee -a "$REPORT"
    [[ -n "$only_repo" ]] && out "${YEL}  in Brewfile but NOT installed locally:${RST}" \
      && echo "$only_repo" | sed 's/^/    - /' | tee -a "$REPORT"
  fi
else
  out "${DIM}  (brew not installed)${RST}"
fi

###############################################################################
# iTerm2 plist
###############################################################################
out ""
header "iTerm2 preferences"
LIVE_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
REPO_PLIST="$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist"
if [[ -f "$LIVE_PLIST" && -f "$REPO_PLIST" ]]; then
  if cmp -s "$LIVE_PLIST" "$REPO_PLIST"; then
    out "${GRN}  identical${RST}"
  else
    # Convert both to XML for a human-readable diff
    tmp_live="$(mktemp)"; tmp_repo="$(mktemp)"
    plutil -convert xml1 -o "$tmp_live" "$LIVE_PLIST"
    plutil -convert xml1 -o "$tmp_repo" "$REPO_PLIST"
    out "${YEL}  binary plists differ — XML diff (truncated to 200 lines):${RST}"
    diff -u --label "repo" --label "live" "$tmp_repo" "$tmp_live" \
      | head -200 | sed 's/^/    /' | tee -a "$REPORT"
    rm -f "$tmp_live" "$tmp_repo"
  fi
else
  [[ ! -f "$LIVE_PLIST" ]] && out "${DIM}  (no $LIVE_PLIST — iTerm2 may not be running from default prefs location)${RST}"
  [[ ! -f "$REPO_PLIST" ]] && out "${DIM}  (no $REPO_PLIST yet — see iterm2/README.md to export)${RST}"
fi

###############################################################################
# Loose ends in $HOME worth surfacing
###############################################################################
out ""
header "Other dotfiles in \$HOME (might be worth adding)"
# Common ones the repo doesn't manage but you might want to.
candidates=(
  ".tmux.conf" ".vimrc" ".ideavimrc" ".inputrc" ".editorconfig"
  ".npmrc" ".curlrc" ".wgetrc" ".ssh/config" ".hushlogin"
  ".config/starship.toml" ".config/git/config"
)
found=0
for f in "${candidates[@]}"; do
  if [[ -e "$HOME/$f" ]] && ! resolve_real "$HOME/$f"; then
    out "  ~/$f"
    found=1
  fi
done
[[ "$found" == 0 ]] && out "${DIM}  (none of the common extras found)${RST}"

out ""
out "${BOLD}Report saved to:${RST} $REPORT"
