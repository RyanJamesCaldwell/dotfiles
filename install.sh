#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/RyanJamesCaldwell/dotfiles.git"
CHEZMOI_SOURCE_DIR="${HOME}/.local/share/chezmoi"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE=""

if [[ -f "${SCRIPT_DIR}/Brewfile" ]]; then
  BREWFILE="${SCRIPT_DIR}/Brewfile"
elif [[ -f "${CHEZMOI_SOURCE_DIR}/Brewfile" ]]; then
  BREWFILE="${CHEZMOI_SOURCE_DIR}/Brewfile"
fi

log() {
  printf "\033[1;34m[install]\033[0m %s\n" "$*"
}

warn() {
  printf "\033[1;33m[warn]\033[0m %s\n" "$*"
}

run() {
  log "→ $*"
  "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    warn "This bootstrap script targets macOS with Homebrew."
    return 1
  fi
}

ensure_command_line_tools() {
  if command_exists xcode-select && ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (interactive prompt expected)..."
    xcode-select --install || warn "Re-run the script after the tools finish installing."
    while ! xcode-select -p >/dev/null 2>&1; do
      sleep 10
    done
  fi
}

ensure_homebrew() {
  if ! command_exists brew; then
    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      export PATH="/opt/homebrew/bin:${PATH}"
    fi
  fi
}

ensure_brew_formula() {
  local formula="$1"
  if ! brew list --formula "$formula" >/dev/null 2>&1; then
    run brew install "$formula"
  fi
}

ensure_brew_cask() {
  local cask="$1"
  if ! brew list --cask "$cask" >/dev/null 2>&1; then
    run brew install --cask "$cask"
  fi
}

ensure_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log "Installing oh-my-zsh..."
    RUNZSH=no KEEP_ZSHRC=yes \curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
  fi
}

ensure_fzf_shell_bindings() {
  local fzf_prefix
  fzf_prefix="$(brew --prefix fzf 2>/dev/null || true)"
  if [[ -n "$fzf_prefix" && -x "${fzf_prefix}/install" ]]; then
    RUNZSH=no "${fzf_prefix}/install" --key-bindings --completion --no-update-rc >/dev/null
  fi
}

ensure_pnpm_setup() {
  if command_exists pnpm; then
    PNPM_HOME="${PNPM_HOME:-${HOME}/Library/pnpm}"
    mkdir -p "${PNPM_HOME}"
    pnpm setup >/dev/null 2>&1 || true
  fi
}

ensure_nvm_dirs() {
  mkdir -p "${HOME}/.nvm"
}

apply_chezmoi() {
  if ! command_exists chezmoi; then
    warn "chezmoi is not available yet; ensure Homebrew installation succeeded."
    return
  fi

  local source_path
  source_path="$(chezmoi source-path 2>/dev/null || true)"

  if [[ -z "$source_path" ]]; then
    if [[ -d "${SCRIPT_DIR}/.git" ]]; then
      run chezmoi init --apply --source="${SCRIPT_DIR}"
    else
      run chezmoi init --apply "${REPO_URL}"
    fi
  else
    run chezmoi git pull -- --rebase || warn "chezmoi git pull failed; resolve manually."
    run chezmoi apply --keep-going
  fi
}

main() {
  ensure_macos
  ensure_command_line_tools
  ensure_homebrew
  run brew update

  if [[ -n "$BREWFILE" ]]; then
    run brew bundle --file "$BREWFILE"
  else
    warn "No Brewfile found; skipping brew bundle step."
  fi

  ensure_brew_formula starship
  ensure_brew_formula pnpm
  ensure_brew_formula nvm
  ensure_brew_cask wezterm
  ensure_oh_my_zsh
  ensure_fzf_shell_bindings
  ensure_nvm_dirs
  ensure_pnpm_setup

  mkdir -p "${HOME}/.local/bin"

  apply_chezmoi

  log "Environment bootstrap complete. Open a new shell to load zsh configuration."
}

main "$@"
