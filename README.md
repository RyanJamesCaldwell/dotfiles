# dotfiles

Personal macOS environment managed with [chezmoi](https://www.chezmoi.io/). This repository keeps shell, Neovim, Git, and terminal configuration reproducible across machines using Homebrew for package management.

## Quick Start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/RyanJamesCaldwell/dotfiles/main/install.sh)"
```

The bootstrap script installs essential dependencies, runs `brew bundle`, and applies the chezmoi-managed files.

## Highlights

- **Shell**: Zsh with oh-my-zsh, fzf integration, starship prompt, aliases tuned for git, and `wt` sourced from `~/.config/wt/wt.zsh`.
- **Editor**: Kickstart-based Neovim setup with Stylua formatting and lazily-loaded plugins.
- **Terminal**: WezTerm configuration for pane-focused workflows, rose-pine colors, and JetBrainsMono Nerd Font.
- **Packages**: Brewfile defines CLI tools (asdf, gh, ripgrep, etc.) and GUI apps (WezTerm, ngrok, 1Password CLI).

## Theming

Theme selection is shared across Zsh/Starship, Neovim, and WezTerm through `~/.config/theme/current`.

- **Available themes**: `sakura_night` (default), `ashfall`, `rosepine`
- **From shell**: run `theme <sakura_night|ashfall|rosepine>`
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

1. Edit files under this repo (e.g., `dot_zshrc`, `dot_config/nvim/init.lua`).
2. Run `chezmoi apply` to sync changes into `$HOME`.
3. Commit updates with descriptive messages and push to GitHub.

Use `chezmoi diff` to inspect changes before applying, and `chezmoi doctor` to verify templates on new hosts.

## Profiles

- Drop `work` or `personal` into `~/.chezmoi_profile` (not tracked in git) to pick the active configuration; the default remains `personal` when the file is absent.
- Chezmoi exposes the selection to templates as `.profile`, which currently feeds into `CHEZMOI_PROFILE` and optional overrides sourced from `~/.zshrc.<profile>`.
- After toggling profiles, rerun `chezmoi apply` (and optionally `chezmoi diff`) to materialize the right variant.

## License

MIT License © Ryan Caldwell
