# dotfiles

Personal macOS and Ubuntu/Debian environment managed with [chezmoi](https://www.chezmoi.io/). This repository keeps shell, Neovim, Git, and terminal configuration reproducible across machines using Homebrew on macOS and apt (plus a handful of upstream release binaries) on Linux.

## Quick Start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/RyanJamesCaldwell/dotfiles/main/install.sh)"
```

The bootstrap script detects the operating system, installs the essential dependencies, and applies the chezmoi-managed files.

```bash
./install.sh            # full install
./install.sh --minimal  # shell + editor essentials only (also: DOTFILES_MINIMAL=1)
```

`--minimal` skips GUI applications, fonts, language-runtime managers, and heavy services — useful for servers, containers, and CI. When bootstrapping remotely, prefer the environment variable, because `bash -c` assigns the first extra argument to `$0`:

```bash
DOTFILES_MINIMAL=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/RyanJamesCaldwell/dotfiles/main/install.sh)"
```

## Platform Support

| Platform | Package source | Notes |
| --- | --- | --- |
| macOS | Homebrew (`Brewfile`) | Reference platform; the rendered configuration is unchanged by Linux support. |
| Ubuntu / Debian | apt + upstream release binaries in `~/.local/bin` | Neovim, starship, chezmoi, lazygit, and (when apt is too old) fzf/eza/delta/gh come from upstream releases. |

Configuration is kept as close to identical as the platforms allow. Differences are expressed as chezmoi conditionals on `.chezmoi.os`, so each machine gets a single-platform `~/.zshrc` rather than runtime branching:

- Homebrew paths, `terminal-notifier`, and the `Library/pnpm` prefix are macOS-only.
- Linux uses `notify-send`, `~/.local/share/pnpm`, and `/usr/share/zsh-*` plugin paths.
- macOS-only tools (`jordanbaird-ice`, `meetingbar`, `terminal-notifier`, `openapi-generator`) are simply not installed on Linux; the shell degrades gracefully when a tool is absent.

The parity table mapping every `Brewfile` entry to its Linux equivalent lives in a comment block inside `install.sh`.

## Highlights

- **Shell**: Zsh with oh-my-zsh, fzf integration, starship prompt, lazy nvm/asdf loading, aliases tuned for git, and `wt` sourced from `~/.config/wt/wt.zsh`.
- **Editor**: Kickstart-based Neovim setup with Stylua formatting and lazily-loaded plugins.
- **Terminal**: WezTerm configuration for pane-focused workflows, rose-pine colors, and JetBrainsMono Nerd Font.
- **Packages**: Brewfile defines CLI tools (asdf, gh, ripgrep, etc.) and GUI apps (WezTerm, ngrok, 1Password CLI).

## Theming

Theme selection is shared across Zsh/Starship, Neovim, and WezTerm through `~/.config/theme/current`.

- **Available themes**: `sakura_night` (default), `ashfall`, `rosepine`
- **From shell**:
  - `theme` or `theme current` shows the active theme
  - `theme list` shows valid themes
  - `theme pick` opens an fzf picker when available, with a numbered fallback
  - `theme <sakura_night|ashfall|rosepine>` applies a theme directly
- **From Neovim**:
  - `:ThemeSet <sakura_night|ashfall|rosepine>`
  - `:ThemeToggle` (cycles through all themes)
- **From WezTerm**: reads `~/.config/theme/current` and applies the matching scheme automatically (`sakura_night`, `ashfall`, or `rose-pine` for `rosepine`)

Theme files live in:

- `dot_config/starship/themes/` for Starship
- `dot_config/nvim/lua/custom/` for custom Neovim palettes
- `dot_wezterm.lua` for WezTerm theme mappings and tab bar styling
If WezTerm is already open, it picks up theme changes automatically (status refresh interval is ~1s).

## Updating Configs

1. Edit files under this repo (e.g., `dot_zshrc.tmpl`, `dot_config/nvim/init.lua`).
2. Run `chezmoi apply` to sync changes into `$HOME`.
3. Commit updates with descriptive messages and push to GitHub.

Use `chezmoi diff` to inspect changes before applying, and `chezmoi doctor` to verify templates on new hosts.

## Verifying an Install

`.github/scripts/verify-dotfiles.sh` checks that a bootstrapped machine matches this repository: managed files exist, the platform-specific `~/.zshrc` rendered correctly, core commands resolve, `chezmoi verify` reports no drift, and an interactive Zsh exposes the `theme`/`profile`/`wt` helpers.

```bash
.github/scripts/verify-dotfiles.sh "$PWD"
```

CI runs two jobs on every push and pull request:

- **Validate dotfiles** (`macos-latest`) — Brewfile lint, chezmoi dry-run render, Stylua formatting, and a Neovim plugin sync.
- **Bootstrap on Ubuntu** (`ubuntu-latest`) — runs `./install.sh --minimal` twice (proving idempotency) and then the verification script.

## Profiles

- Drop `work` or `personal` into `~/.chezmoi_profile` (not tracked in git) to pick the active configuration; the default remains `personal` when the file is absent.
- Chezmoi exposes the selection to templates as `.profile`, which currently feeds into `CHEZMOI_PROFILE` and optional overrides sourced from `~/.zshrc.<profile>`.
- Use `profile current`, `profile list`, `profile pick`, or `profile <personal|work>` from Zsh to inspect or switch profiles.
- The `profile` helper writes `~/.chezmoi_profile`, updates `CHEZMOI_PROFILE` in the current shell, runs `chezmoi apply` when available, and sends a terminal notification when possible.

## Shell Startup

- nvm and asdf are lazy-loaded to keep startup fast while preserving shims and command behavior.
- Run `zsh-startup-profile` to launch a one-shot profiled shell and print `zprof` output without adding overhead to normal startup.

## License

MIT License © Ryan Caldwell
