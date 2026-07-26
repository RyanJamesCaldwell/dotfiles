#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/RyanJamesCaldwell/dotfiles.git"
CHEZMOI_SOURCE_DIR="${HOME}/.local/share/chezmoi"
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
else
  # Piped into `bash -c`, so there is no script path to resolve.
  SCRIPT_DIR="$PWD"
fi
LOCAL_BIN="${HOME}/.local/bin"
BREWFILE=""
OS_FAMILY=""
LINUX_PKG_MANAGER=""
SUDO=""
MINIMAL="${DOTFILES_MINIMAL:-0}"

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

# Optional step: log a warning instead of aborting the whole bootstrap. The
# subshell keeps `errexit` active inside the callee; bash would otherwise
# disable it for the whole call because `if !` is a condition context.
try_run() {
  log "→ $*"
  local rc=0
  set +e
  (
    set -e
    "$@"
  )
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    warn "Optional step failed: $*"
  fi
  return 0
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_minimal() {
  [[ "$MINIMAL" == "1" ]]
}

usage() {
  cat <<'USAGE'
Usage: install.sh [--minimal] [--help]

  --minimal   Install only the packages needed for the shell, editor, and
              chezmoi-managed configuration. Skips GUI apps, fonts, language
              runtime managers, and heavy services. Also settable via
              DOTFILES_MINIMAL=1, which is the reliable way to pass it when
              bootstrapping with `bash -c "$(curl ...)"`.
  --help      Show this message.

Supported platforms: macOS (Homebrew) and Debian/Ubuntu Linux (apt).
USAGE
}

detect_os() {
  case "$(uname -s)" in
    Darwin) OS_FAMILY="darwin" ;;
    Linux) OS_FAMILY="linux" ;;
    *)
      warn "Unsupported operating system: $(uname -s)"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------

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

ensure_fzf_shell_bindings() {
  local fzf_prefix
  fzf_prefix="$(brew --prefix fzf 2>/dev/null || true)"
  if [[ -n "$fzf_prefix" && -x "${fzf_prefix}/install" ]]; then
    RUNZSH=no "${fzf_prefix}/install" --key-bindings --completion --no-update-rc >/dev/null
  fi
}

install_macos_packages() {
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
  ensure_fzf_shell_bindings
}

# ---------------------------------------------------------------------------
# Linux (Debian/Ubuntu)
#
# Parity with the Brewfile. Anything listed as "unavailable" simply is not
# installed on Linux; the shell/editor configuration degrades gracefully.
#
#   Brewfile entry          Linux equivalent
#   ----------------------  ---------------------------------------------
#   asdf                    GitHub release binary (extras)
#   azure-cli               unavailable by default (extras, Microsoft apt repo)
#   bat                     apt `bat` (binary is batcat, shimmed to bat)
#   btop                    apt `btop` (extras)
#   chafa                   apt `chafa` (extras)
#   chezmoi                 get.chezmoi.io installer
#   coreutils               built in
#   curl                    apt `curl`
#   eza                     apt `eza`, else GitHub release binary
#   fd                      apt `fd-find` (binary is fdfind, shimmed to fd)
#   fzf                     apt `fzf`, upgraded from GitHub when too old
#   gh                      apt `gh`, else GitHub release binary
#   git                     apt `git`
#   git-delta               apt `git-delta`, else GitHub release binary
#   glow                    GitHub release binary (extras)
#   imagemagick             apt `imagemagick` (extras)
#   jq                      apt `jq`
#   lazygit                 GitHub release binary
#   lua / luarocks          apt `lua5.4` / `luarocks` (extras)
#   neovim                  GitHub release tarball (apt is usually too old)
#   nginx                   apt `nginx` (extras)
#   openapi-generator       unavailable (needs a JVM; install manually)
#   postgresql@14           apt `postgresql` (16 on Ubuntu 24.04, extras)
#   python@3.x              apt `python3` (extras)
#   ripgrep                 apt `ripgrep`
#   terminal-notifier       apt `libnotify-bin` (notify-send)
#   zrok                    unavailable by default (extras, openziti repo)
#   zsh-autosuggestions     apt `zsh-autosuggestions`
#   zsh-syntax-highlighting apt `zsh-syntax-highlighting`
#   bun                     GitHub release binary (extras)
#   stripe-cli              unavailable by default (extras)
#   zoxide                  apt `zoxide`, else official installer
#   1password-cli           unavailable by default (extras, 1Password repo)
#   font-jetbrains-mono     Nerd Fonts release zip (extras)
#   jordanbaird-ice         unavailable (macOS only)
#   meetingbar              unavailable (macOS only)
#   mitmproxy               apt `mitmproxy` (extras)
#   ngrok                   unavailable by default (extras, ngrok repo)
#   wezterm                 GitHub release .deb (extras)
#
# Installed on both platforms but not listed in the Brewfile:
#   nvm                     nvm-sh install.sh with PROFILE=/dev/null (extras)
#   pnpm                    GitHub release tarball (extras)
#   starship                starship.rs installer
# ---------------------------------------------------------------------------

LINUX_CORE_APT_PACKAGES=(
  bat
  ca-certificates
  curl
  fd-find
  file
  fzf
  git
  gnupg
  jq
  less
  libnotify-bin
  ripgrep
  tar
  unzip
  xz-utils
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Present in some releases only; installed individually so one miss does not
# fail the whole transaction.
LINUX_CORE_APT_OPTIONAL_PACKAGES=(
  eza
  gh
  git-delta
  zoxide
)

LINUX_EXTRA_APT_PACKAGES=(
  btop
  build-essential
  chafa
  imagemagick
  lua5.4
  luarocks
  mitmproxy
  nginx
  postgresql
  python3
  python3-venv
)

detect_linux_pkg_manager() {
  if command_exists apt-get; then
    LINUX_PKG_MANAGER="apt"
  else
    LINUX_PKG_MANAGER=""
    warn "No apt-get found; skipping system package installation."
  fi
}

detect_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
    return
  fi

  if ! command_exists sudo; then
    SUDO=""
    LINUX_PKG_MANAGER=""
    warn "Not root and sudo is unavailable; skipping system package installation."
    return
  fi

  SUDO="sudo"

  # Without a terminal there is no way to answer a sudo password prompt, so
  # skip the system packages instead of hanging or aborting the bootstrap.
  if ! sudo -n true >/dev/null 2>&1 && [[ ! -t 0 ]]; then
    SUDO=""
    LINUX_PKG_MANAGER=""
    warn "sudo needs a password and no terminal is attached; skipping system package installation."
  fi
}

apt_get() {
  if [[ -n "$SUDO" ]]; then
    "$SUDO" env DEBIAN_FRONTEND=noninteractive apt-get "$@"
  else
    DEBIAN_FRONTEND=noninteractive apt-get "$@"
  fi
}

ensure_apt_packages() {
  [[ "$LINUX_PKG_MANAGER" == "apt" ]] || return 0

  run apt_get update -y
  run apt_get install -y --no-install-recommends "${LINUX_CORE_APT_PACKAGES[@]}"

  local package
  for package in "${LINUX_CORE_APT_OPTIONAL_PACKAGES[@]}"; do
    apt_get install -y --no-install-recommends "$package" >/dev/null 2>&1 ||
      warn "apt package '$package' is unavailable on this release; using a fallback."
  done

  is_minimal && return 0

  for package in "${LINUX_EXTRA_APT_PACKAGES[@]}"; do
    apt_get install -y --no-install-recommends "$package" >/dev/null 2>&1 ||
      warn "apt package '$package' is unavailable on this release; skipping."
  done
}

# Debian renames a couple of binaries to avoid collisions; restore the names the
# rest of the configuration (and muscle memory) expects.
ensure_debian_binary_shims() {
  mkdir -p "$LOCAL_BIN"
  if ! command_exists bat && command_exists batcat; then
    run ln -sf "$(command -v batcat)" "${LOCAL_BIN}/bat"
  fi
  if ! command_exists fd && command_exists fdfind; then
    run ln -sf "$(command -v fdfind)" "${LOCAL_BIN}/fd"
  fi
}

linux_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) printf 'x86_64\n' ;;
    aarch64 | arm64) printf 'aarch64\n' ;;
    *) return 1 ;;
  esac
}

# Resolve the newest release tag without spending GitHub API rate limit.
github_latest_tag() {
  local repo="$1" effective_url
  effective_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/${repo}/releases/latest" 2>/dev/null)" || return 1
  local tag="${effective_url##*/}"
  [[ -n "$tag" && "$tag" != "latest" ]] || return 1
  printf '%s\n' "$tag"
}

# install_github_archive <repo> <asset-template> <binary-path-template> <bin-name>
# Templates may use {tag} (e.g. v0.44.1), {version} (0.44.1) and {arch}.
install_github_archive() {
  local repo="$1" asset_template="$2" binary_template="$3" bin_name="$4"
  local arch tag version asset binary_path tmp_dir url

  arch="$(linux_arch)" || {
    warn "Unsupported architecture $(uname -m) for ${bin_name}."
    return 1
  }
  tag="$(github_latest_tag "$repo")" || {
    warn "Could not resolve the latest ${repo} release."
    return 1
  }
  version="${tag#v}"

  asset="${asset_template//\{tag\}/$tag}"
  asset="${asset//\{version\}/$version}"
  asset="${asset//\{arch\}/$arch}"

  binary_path="${binary_template//\{tag\}/$tag}"
  binary_path="${binary_path//\{version\}/$version}"
  binary_path="${binary_path//\{arch\}/$arch}"

  url="https://github.com/${repo}/releases/download/${tag}/${asset}"
  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN

  log "Downloading ${repo} ${tag} (${asset})"
  curl -fsSL "$url" -o "${tmp_dir}/${asset}" || {
    warn "Download failed: ${url}"
    return 1
  }

  case "$asset" in
    *.tar.gz | *.tgz) tar -xzf "${tmp_dir}/${asset}" -C "$tmp_dir" || return 1 ;;
    *.zip) unzip -qo "${tmp_dir}/${asset}" -d "$tmp_dir" || return 1 ;;
    *)
      warn "Unsupported archive format for ${asset}."
      return 1
      ;;
  esac

  if [[ ! -f "${tmp_dir}/${binary_path}" ]]; then
    warn "Expected ${binary_path} inside ${asset} but it was not found."
    return 1
  fi

  mkdir -p "$LOCAL_BIN" || return 1
  install -m 0755 "${tmp_dir}/${binary_path}" "${LOCAL_BIN}/${bin_name}" || return 1
  log "Installed ${bin_name} ${tag} to ${LOCAL_BIN}"
}

ensure_linux_chezmoi() {
  command_exists chezmoi && return 0
  log "Installing chezmoi..."
  mkdir -p "$LOCAL_BIN"
  # Piped rather than `sh -c "$(curl ...)"` so that a failed download is not
  # silently turned into an empty, successful script.
  curl -fsLS get.chezmoi.io | sh -s -- -b "$LOCAL_BIN"
  hash -r 2>/dev/null || true
  command_exists chezmoi || {
    warn "chezmoi is still not on PATH after installation."
    return 1
  }
}

ensure_linux_starship() {
  command_exists starship && return 0
  log "Installing starship..."
  mkdir -p "$LOCAL_BIN"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN"
}

ensure_linux_zoxide() {
  if command_exists zoxide && zoxide init --cmd cd zsh >/dev/null 2>&1; then
    return 0
  fi
  log "Installing zoxide..."
  mkdir -p "$LOCAL_BIN"
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
    sh -s -- --bin-dir "$LOCAL_BIN"
}

ensure_linux_eza() {
  command_exists eza && return 0
  install_github_archive eza-community/eza \
    'eza_{arch}-unknown-linux-gnu.tar.gz' './eza' eza
}

ensure_linux_delta() {
  command_exists delta && return 0
  install_github_archive dandavison/delta \
    'delta-{tag}-{arch}-unknown-linux-gnu.tar.gz' \
    'delta-{tag}-{arch}-unknown-linux-gnu/delta' delta
}

ensure_linux_lazygit() {
  command_exists lazygit && return 0
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="x86_64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  install_github_archive jesseduffield/lazygit \
    "lazygit_{version}_Linux_${asset_arch}.tar.gz" 'lazygit' lazygit
}

ensure_linux_gh() {
  command_exists gh && return 0
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="amd64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  install_github_archive cli/cli \
    "gh_{version}_linux_${asset_arch}.tar.gz" \
    "gh_{version}_linux_${asset_arch}/bin/gh" gh
}

# The zsh configuration uses `fzf --zsh`, added in fzf 0.48.
ensure_linux_fzf() {
  if command_exists fzf && fzf --zsh >/dev/null 2>&1; then
    return 0
  fi
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="amd64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  install_github_archive junegunn/fzf \
    "fzf-{version}-linux_${asset_arch}.tar.gz" 'fzf' fzf
}

# Ubuntu/Debian neovim packages lag well behind what this Neovim config needs.
ensure_linux_neovim() {
  local current_version=""
  if command_exists nvim; then
    current_version="$(nvim --version 2>/dev/null | sed -n '1p' || true)"
  fi
  if [[ "$current_version" =~ v0\.(9|[1-9][0-9]) || "$current_version" =~ v[1-9][0-9]*\. ]]; then
    return 0
  fi

  local arch asset tag tmp_dir target
  case "$(uname -m)" in
    x86_64 | amd64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      warn "Unsupported architecture $(uname -m) for Neovim."
      return 1
      ;;
  esac

  tag="$(github_latest_tag neovim/neovim)" || {
    warn "Could not resolve the latest Neovim release."
    return 1
  }

  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN

  local downloaded="" candidates=("nvim-linux-${arch}.tar.gz")
  # `nvim-linux64.tar.gz` is the legacy x86_64-only asset name.
  [[ "$arch" == "x86_64" ]] && candidates+=("nvim-linux64.tar.gz")

  for asset in "${candidates[@]}"; do
    log "Downloading Neovim ${tag} (${asset})"
    if curl -fsSL "https://github.com/neovim/neovim/releases/download/${tag}/${asset}" \
      -o "${tmp_dir}/nvim.tar.gz"; then
      downloaded="$asset"
      break
    fi
  done

  if [[ -z "$downloaded" ]]; then
    warn "Could not download a Neovim release for ${arch}."
    return 1
  fi

  tar -xzf "${tmp_dir}/nvim.tar.gz" -C "$tmp_dir" || return 1
  local extracted
  extracted="$(find "$tmp_dir" -maxdepth 1 -type d -name 'nvim-*' | head -n1)"
  [[ -n "$extracted" ]] || {
    warn "Unexpected Neovim archive layout."
    return 1
  }

  target="${HOME}/.local/share/nvim-release"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")" || return 1
  mv "$extracted" "$target" || return 1
  mkdir -p "$LOCAL_BIN" || return 1
  ln -sf "${target}/bin/nvim" "${LOCAL_BIN}/nvim" || return 1
  log "Installed Neovim ${tag} to ${target}"
}

ensure_linux_glow() {
  command_exists glow && return 0
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="x86_64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  install_github_archive charmbracelet/glow \
    "glow_{version}_Linux_${asset_arch}.tar.gz" \
    "glow_{version}_Linux_${asset_arch}/glow" glow
}

ensure_linux_asdf() {
  command_exists asdf && return 0
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="amd64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  install_github_archive asdf-vm/asdf \
    "asdf-{tag}-linux-${asset_arch}.tar.gz" 'asdf' asdf
}

ensure_linux_bun() {
  command_exists bun && return 0
  local asset_arch
  case "$(linux_arch)" in
    x86_64) asset_arch="x64" ;;
    aarch64) asset_arch="aarch64" ;;
    *) return 1 ;;
  esac
  install_github_archive oven-sh/bun \
    "bun-linux-${asset_arch}.zip" "bun-linux-${asset_arch}/bun" bun
}

# Installed from the release tarball rather than get.pnpm.io so that the
# installer does not append its own exports to the chezmoi-managed ~/.zshrc.
ensure_linux_pnpm() {
  command_exists pnpm && return 0

  local asset_arch tag tmp_dir target pnpm_home
  case "$(linux_arch)" in
    x86_64) asset_arch="x64" ;;
    aarch64) asset_arch="arm64" ;;
    *) return 1 ;;
  esac
  tag="$(github_latest_tag pnpm/pnpm)" || return 1

  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN

  log "Downloading pnpm ${tag} (pnpm-linux-${asset_arch}.tar.gz)"
  curl -fsSL "https://github.com/pnpm/pnpm/releases/download/${tag}/pnpm-linux-${asset_arch}.tar.gz" \
    -o "${tmp_dir}/pnpm.tar.gz" || return 1

  target="${HOME}/.local/share/pnpm-dist"
  rm -rf "$target"
  mkdir -p "$target" || return 1
  tar -xzf "${tmp_dir}/pnpm.tar.gz" -C "$target" || return 1
  chmod +x "${target}/pnpm" || return 1

  pnpm_home="${HOME}/.local/share/pnpm"
  mkdir -p "$pnpm_home" "$LOCAL_BIN" || return 1
  ln -sf "${target}/pnpm" "${pnpm_home}/pnpm" || return 1
  ln -sf "${target}/pnpm" "${LOCAL_BIN}/pnpm" || return 1
  log "Installed pnpm ${tag} to ${target}"
}

# PROFILE=/dev/null keeps the installer from editing the managed ~/.zshrc.
ensure_linux_nvm() {
  [[ -s "${NVM_DIR:-${HOME}/.nvm}/nvm.sh" ]] && return 0
  log "Installing nvm..."
  local tag
  tag="$(github_latest_tag nvm-sh/nvm)" || return 1
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${tag}/install.sh" |
    PROFILE=/dev/null bash
}

ensure_linux_wezterm() {
  command_exists wezterm && return 0
  [[ "$LINUX_PKG_MANAGER" == "apt" ]] || return 0

  local tag tmp_dir distro_id version_id arch_suffix
  tag="$(github_latest_tag wez/wezterm)" || return 1

  distro_id="$( (. /etc/os-release 2>/dev/null && printf '%s\n' "${ID:-}") || true)"
  version_id="$( (. /etc/os-release 2>/dev/null && printf '%s\n' "${VERSION_ID:-}") || true)"

  arch_suffix=""
  [[ "$(linux_arch)" == "aarch64" ]] && arch_suffix=".arm64"

  # WezTerm names its .deb assets after the distro version rather than the
  # codename (wezterm-<tag>.Ubuntu22.04.arm64.deb) and only publishes a handful
  # of them, so fall back to the newest release that does exist.
  local -a candidates=()
  case "$distro_id" in
    debian) [[ -n "$version_id" ]] && candidates+=("Debian${version_id%%.*}${arch_suffix}") ;;
    *) [[ -n "$version_id" ]] && candidates+=("Ubuntu${version_id}${arch_suffix}") ;;
  esac
  candidates+=("Ubuntu22.04${arch_suffix}" "Debian12${arch_suffix}")

  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN

  local candidate downloaded=""
  for candidate in "${candidates[@]}"; do
    if curl -fsSL "https://github.com/wez/wezterm/releases/download/${tag}/wezterm-${tag}.${candidate}.deb" \
      -o "${tmp_dir}/wezterm.deb"; then
      downloaded="$candidate"
      break
    fi
  done

  if [[ -z "$downloaded" ]]; then
    warn "No WezTerm .deb is published for ${distro_id:-linux} ${version_id:-?} on $(uname -m)."
    return 1
  fi

  log "Installing WezTerm ${tag} (${downloaded})"
  apt_get install -y "${tmp_dir}/wezterm.deb"
}

ensure_linux_nerd_font() {
  local font_dir="${HOME}/.local/share/fonts"
  [[ -d "${font_dir}/JetBrainsMono" ]] && return 0

  local tag tmp_dir
  tag="$(github_latest_tag ryanoasis/nerd-fonts)" || return 1
  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN

  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/JetBrainsMono.zip" \
    -o "${tmp_dir}/JetBrainsMono.zip" || return 1
  mkdir -p "${font_dir}/JetBrainsMono" || return 1
  unzip -qo "${tmp_dir}/JetBrainsMono.zip" -d "${font_dir}/JetBrainsMono" || return 1
  command_exists fc-cache && fc-cache -f "${font_dir}" >/dev/null 2>&1
  log "Installed JetBrainsMono Nerd Font"
}

install_linux_packages() {
  detect_linux_pkg_manager
  detect_sudo

  export PATH="${LOCAL_BIN}:${PATH}"

  ensure_apt_packages
  ensure_debian_binary_shims

  ensure_linux_chezmoi
  ensure_linux_starship
  ensure_linux_neovim
  try_run ensure_linux_zoxide
  try_run ensure_linux_eza
  try_run ensure_linux_delta
  try_run ensure_linux_lazygit
  try_run ensure_linux_gh
  try_run ensure_linux_fzf

  # Newly installed binaries may shadow earlier lookups.
  hash -r 2>/dev/null || true

  if is_minimal; then
    log "Minimal install: skipping optional Linux packages."
    return 0
  fi

  try_run ensure_linux_glow
  try_run ensure_linux_asdf
  try_run ensure_linux_bun
  try_run ensure_linux_pnpm
  try_run ensure_linux_nvm
  try_run ensure_linux_wezterm
  try_run ensure_linux_nerd_font

  hash -r 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------

ensure_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log "Installing oh-my-zsh..."
    # The settings have to be applied to bash (the interpreter) rather than to
    # curl. ~/.zshrc is owned by chezmoi and the login shell is handled
    # separately, so opt out of both.
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |
      ZSH="${HOME}/.oh-my-zsh" RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash
  fi
}

report_login_shell() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || return 0
  [[ "$(basename -- "${SHELL:-}")" == "zsh" ]] && return 0
  warn "Your login shell is ${SHELL:-unknown}. Run 'chsh -s ${zsh_path}' to switch to zsh."
}

ensure_pnpm_setup() {
  if command_exists pnpm; then
    if [[ "$OS_FAMILY" == "darwin" ]]; then
      PNPM_HOME="${PNPM_HOME:-${HOME}/Library/pnpm}"
      mkdir -p "${PNPM_HOME}" 2>/dev/null || warn "Could not create PNPM_HOME at ${PNPM_HOME}"
      pnpm setup >/dev/null 2>&1 || true
    else
      # `pnpm setup` rewrites shell rc files, which chezmoi owns on Linux; the
      # zsh template already exports PNPM_HOME and puts it on PATH.
      PNPM_HOME="${PNPM_HOME:-${HOME}/.local/share/pnpm}"
      mkdir -p "${PNPM_HOME}" 2>/dev/null || warn "Could not create PNPM_HOME at ${PNPM_HOME}"
    fi
  fi
}

ensure_nvm_dirs() {
  mkdir -p "${HOME}/.nvm"
}

apply_chezmoi() {
  if ! command_exists chezmoi; then
    warn "chezmoi is not available; the configuration was not applied."
    return 1
  fi

  local source_path
  source_path="$(chezmoi source-path 2>/dev/null || true)"

  # `chezmoi source-path` reports the default location even when it has never
  # been initialised, so the directory has to be checked as well.
  if [[ -n "$source_path" && -d "$source_path" ]]; then
    run chezmoi git pull -- --rebase || warn "chezmoi git pull failed; resolve manually."
    run chezmoi apply --keep-going
    return
  fi

  # `.git` is a file rather than a directory inside a git worktree.
  if [[ -e "${SCRIPT_DIR}/.git" ]]; then
    run chezmoi init --apply --source="${SCRIPT_DIR}"
  else
    run chezmoi init --apply "${REPO_URL}"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --minimal)
        MINIMAL=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        warn "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  detect_os

  is_minimal && log "Running a minimal install."

  case "$OS_FAMILY" in
    darwin) install_macos_packages ;;
    linux) install_linux_packages ;;
  esac

  ensure_oh_my_zsh
  ensure_nvm_dirs
  ensure_pnpm_setup

  mkdir -p "${LOCAL_BIN}"

  apply_chezmoi

  report_login_shell

  log "Environment bootstrap complete. Open a new shell to load zsh configuration."
}

main "$@"
