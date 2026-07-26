#!/usr/bin/env bash
# Verifies that a bootstrapped machine ended up with the configuration this
# repository describes. Safe to run on macOS and Linux, and used by CI after
# `install.sh --minimal`.
set -uo pipefail

SOURCE_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export PATH="${HOME}/.local/bin:${PATH}"

FAILURES=0
CHECKS=0

case "$(uname -s)" in
  Darwin) OS_FAMILY="darwin" ;;
  Linux) OS_FAMILY="linux" ;;
  *)
    printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

pass() {
  CHECKS=$((CHECKS + 1))
  printf '\033[1;32m  ok  \033[0m %s\n' "$*"
}

fail() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '\033[1;31m FAIL \033[0m %s\n' "$*"
}

section() {
  printf '\n\033[1;34m==> %s\033[0m\n' "$*"
}

check_file() {
  if [[ -f "$1" ]]; then
    pass "file exists: $1"
  else
    fail "file missing: $1"
  fi
}

check_contains() {
  local file="$1" pattern="$2"
  if grep -qF -- "$pattern" "$file" 2>/dev/null; then
    pass "$(basename "$file") contains: $pattern"
  else
    fail "$(basename "$file") is missing: $pattern"
  fi
}

check_not_contains() {
  local file="$1" pattern="$2"
  if grep -qF -- "$pattern" "$file" 2>/dev/null; then
    fail "$(basename "$file") unexpectedly contains: $pattern"
  else
    pass "$(basename "$file") does not contain: $pattern"
  fi
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command available: $1 ($(command -v "$1"))"
  else
    fail "command missing: $1"
  fi
}

strip_terminal_escapes() {
  LC_ALL=C sed -e $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g' -e $'s/\x1b[()#][A-Za-z0-9]//g' \
    -e $'s/\x1b[A-Za-z=>]//g' -e $'s/\r//g'
}

# macOS does not ship GNU timeout unless coreutils is installed.
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(timeout 120)
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(gtimeout 120)
else
  TIMEOUT_CMD=(env)
fi

# Runs a snippet in a fresh interactive zsh and compares stdout to an expectation.
#
# TERM is cleared because ~/.zshrc runs `tabs -2`, which writes tab-stop escape
# sequences to stdout whenever a terminfo entry is available.
#
# Startup itself can also write to stdout (oh-my-zsh prints an insecure-directory
# banner there, for example), so the snippet output is delimited by a marker and
# everything before it is discarded.
ZSH_PROBE_MARKER='__verify_dotfiles_output__'

check_zsh_output() {
  local description="$1" snippet="$2" expected="$3" raw actual status
  raw="$(env -u TERM "${TIMEOUT_CMD[@]}" zsh -i -c "print -rn -- '${ZSH_PROBE_MARKER}'
${snippet}" 2>/dev/null | strip_terminal_escapes)"
  status=$?

  if [[ $status -ne 0 ]]; then
    fail "${description} (zsh exited with ${status})"
    return
  fi

  if [[ "$raw" != *"${ZSH_PROBE_MARKER}"* ]]; then
    fail "${description}: zsh produced no output marker"
    return
  fi

  actual="${raw#*"${ZSH_PROBE_MARKER}"}"

  if [[ "$actual" == "$expected" ]]; then
    pass "${description} -> ${actual}"
  else
    fail "${description}: expected '${expected}', got '${actual}'"
  fi
}

section "Managed files"
check_file "${HOME}/.zshrc"
check_file "${HOME}/.gitconfig"
check_file "${HOME}/.wezterm.lua"
# Single source of truth for this script, kept in step with THEME_CHOICES in
# dot_zshrc.tmpl. THEME_FAMILY is the generated set that must resolve in three
# places at once; rosepine is served by a Neovim plugin instead of a module.
THEME_FAMILY="nightshade aurora abyss"
ALL_THEMES="${THEME_FAMILY} rosepine"
DEFAULT_THEME="nightshade"

check_file "${HOME}/.config/chezmoi/chezmoi.yaml"
check_file "${HOME}/.config/nvim/init.lua"
check_file "${HOME}/.config/nvim/lazy-lock.json"
check_file "${HOME}/.config/starship.toml"
check_file "${HOME}/.config/starship/themes/rosepine.toml"
for name in ${THEME_FAMILY}; do
  check_file "${HOME}/.config/starship/themes/${name}.toml"
  check_file "${HOME}/.config/nvim/lua/custom/${name}.lua"
done
check_file "${HOME}/.config/wt/wt.zsh"

section "Platform-specific rendering"
if [[ "$OS_FAMILY" == "darwin" ]]; then
  check_contains "${HOME}/.zshrc" '/opt/homebrew/bin'
  check_contains "${HOME}/.zshrc" 'export PNPM_HOME="$HOME/Library/pnpm/pnpm"'
  check_contains "${HOME}/.zshrc" 'terminal-notifier'
else
  check_not_contains "${HOME}/.zshrc" '/opt/homebrew'
  check_not_contains "${HOME}/.zshrc" 'terminal-notifier'
  check_contains "${HOME}/.zshrc" 'export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"'
  check_contains "${HOME}/.zshrc" 'notify-send'
  check_contains "${HOME}/.zshrc" '/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
  check_contains "${HOME}/.zshrc" '/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
fi

section "Core commands"
for tool in zsh git curl chezmoi starship nvim fzf jq rg; do
  check_command "$tool"
done

section "chezmoi state"
# git-repo externals always look "modified" to chezmoi, so they are excluded
# here and asserted separately by the managed-file checks above.
if chezmoi --source="$SOURCE_DIR" --no-tty verify --exclude=externals >/dev/null 2>&1; then
  pass "chezmoi verify reports no drift"
else
  fail "chezmoi verify reports drift"
  chezmoi --source="$SOURCE_DIR" --no-tty status --exclude=externals || true
fi

section "Interactive zsh"
if env -u TERM "${TIMEOUT_CMD[@]}" zsh -i -c 'exit 0' >/dev/null 2>"${TMPDIR:-/tmp}/zsh-startup-stderr.log"; then
  pass "interactive zsh starts cleanly"
  if [[ -s "${TMPDIR:-/tmp}/zsh-startup-stderr.log" ]]; then
    printf '\033[1;33m note \033[0m zsh wrote to stderr during startup:\n'
    sed 's/^/        /' "${TMPDIR:-/tmp}/zsh-startup-stderr.log"
  fi
else
  fail "interactive zsh failed to start"
  sed 's/^/        /' "${TMPDIR:-/tmp}/zsh-startup-stderr.log" || true
fi

check_zsh_output "EDITOR is nvim" 'print -r -- "$EDITOR"' 'nvim'
# A freshly bootstrapped machine has no state file and falls back to the first
# entry in THEME_CHOICES, and a state file left over from an older revision can
# name a retired theme that zsh rightly refuses. Either way the shell reports
# the default; only a currently valid choice should be expected verbatim.
EXPECTED_THEME="$(cat "${HOME}/.config/theme/current" 2>/dev/null || true)"
case " ${ALL_THEMES} " in
  *" ${EXPECTED_THEME} "*) ;;
  *) EXPECTED_THEME="$DEFAULT_THEME" ;;
esac
check_zsh_output "theme reports the persisted choice" 'theme current | head -n1' \
  "Current theme: ${EXPECTED_THEME}"
check_zsh_output "theme list" 'theme list | tr "\n" " " | sed "s/ $//"' \
  "${ALL_THEMES}"
check_zsh_output "profile defaults to personal" 'profile current | head -n1' 'Current profile: personal'
check_zsh_output "starship prompt is initialised" 'print -r -- "$STARSHIP_SHELL"' 'zsh'
# zoxide binds `cd` differently across versions: a function in 0.4.x and 1.x, an
# alias to __zoxide_z in 0.9.x. Assert that cd is overridden *by zoxide* rather
# than pinning any one release's shape or internal symbol names.
check_zsh_output "zoxide overrides cd" '
case "$(whence -w cd)" in
  (*function) [[ "${functions[cd]}" == *zoxide* ]] && print -r -- overridden || print -r -- "cd is a non-zoxide function" ;;
  (*alias) [[ "${aliases[cd]}" == *zoxide* ]] && print -r -- overridden || print -r -- "cd is a non-zoxide alias" ;;
  (*) print -r -- "not overridden: $(whence -w cd)" ;;
esac' 'overridden'
check_zsh_output "l alias is defined" 'whence -w l' 'l: alias'
check_zsh_output "zsh-startup-profile helper exists" 'whence -w zsh-startup-profile' 'zsh-startup-profile: function'
check_zsh_output "wt helpers are sourced" 'whence -w wt' 'wt: function'

# The lazy nvm wrapper is only defined when nvm itself is installed, which the
# minimal bootstrap intentionally skips.
if [[ -s "${NVM_DIR:-${HOME}/.nvm}/nvm.sh" ]]; then
  check_zsh_output "nvm is lazily wrapped" 'whence -w nvm' 'nvm: function'
else
  pass "nvm is not installed; lazy wrapper correctly inactive"
fi

section "Theme switching round-trip"
# These checks rewrite the persisted theme, so remember what was there and put
# it back at the end rather than leaving the machine on a test value.
ORIGINAL_THEME="$(cat "${HOME}/.config/theme/current" 2>/dev/null || true)"
# A state file left over from an older revision can name a retired theme, which
# `theme` rightly rejects; fall back so the restore at the end still succeeds.
case " ${ALL_THEMES} " in
  *" ${ORIGINAL_THEME} "*) ;;
  *) ORIGINAL_THEME="$DEFAULT_THEME" ;;
esac

check_zsh_output "theme rosepine applies" 'theme rosepine' 'Theme set to rosepine'
if [[ "$(cat "${HOME}/.config/theme/current" 2>/dev/null)" == "rosepine" ]]; then
  pass "theme state file updated"
else
  fail "theme state file was not updated"
fi
check_zsh_output "new shell picks up the theme" 'theme current | head -n1' 'Current theme: rosepine'
check_zsh_output "starship config follows the theme" \
  'print -r -- "${STARSHIP_CONFIG:t}"' 'rosepine.toml'
check_zsh_output "invalid theme is rejected" \
  'theme nonsense >/dev/null 2>&1 || print -r -- rejected' 'rejected'

section "Generated theme family"
# Each of these is a full theme, so it has to exist in three places at once: a
# Starship config, a WezTerm scheme and a Neovim module.
for name in ${THEME_FAMILY}; do
  if STARSHIP_CONFIG="${HOME}/.config/starship/themes/${name}.toml" \
    starship print-config >/dev/null 2>&1; then
    pass "starship parses ${name}.toml"
  else
    fail "starship rejected ${name}.toml"
  fi

  check_contains "${HOME}/.wezterm.lua" "${name} = {"
  check_zsh_output "theme ${name} applies" "theme ${name}" "Theme set to ${name}"
  check_zsh_output "starship config follows ${name}" \
    'print -r -- "${STARSHIP_CONFIG:t}"' "${name}.toml"
  check_zsh_output "NVIM_THEME follows ${name}" 'print -r -- "$NVIM_THEME"' "${name}"
done

# Loading each module for real is the only way to catch a bad highlight spec:
# a Lua syntax check still passes on arguments that nvim_set_hl rejects.
if command -v nvim >/dev/null 2>&1; then
  for name in ${THEME_FAMILY}; do
    if nvim --headless --clean --cmd "set runtimepath+=${HOME}/.config/nvim" \
      -c "lua require('custom.${name}').setup()" -c 'quitall!' >/dev/null 2>&1; then
      pass "neovim loads the ${name} colorscheme"
    else
      fail "neovim failed to load the ${name} colorscheme"
    fi
  done
else
  pass "neovim is not installed; colorscheme load checks correctly skipped"
fi

check_zsh_output "theme restores the original" "theme ${ORIGINAL_THEME}" \
  "Theme set to ${ORIGINAL_THEME}"

section "Summary"
printf '%d checks, %d failures\n' "$CHECKS" "$FAILURES"
[[ "$FAILURES" -eq 0 ]]
