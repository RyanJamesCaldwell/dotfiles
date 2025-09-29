# dotfiles

Personal macOS environment managed with [chezmoi](https://www.chezmoi.io/). This repository keeps shell, Neovim, Git, and terminal configuration reproducible across machines using Homebrew for package management.

## Quick Start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/RyanJamesCaldwell/dotfiles/main/install.sh)"
```

The bootstrap script installs essential dependencies, runs `brew bundle`, and applies the chezmoi-managed files.

## Highlights

- **Shell**: Zsh with oh-my-zsh, fzf integration, starship prompt, and aliases tuned for git.
- **Editor**: Kickstart-based Neovim setup with Stylua formatting and lazily-loaded plugins.
- **Terminal**: WezTerm configuration for pane-focused workflows, rose-pine colors, and JetBrainsMono Nerd Font.
- **Packages**: Brewfile defines CLI tools (asdf, gh, ripgrep, etc.) and GUI apps (WezTerm, ngrok, 1Password CLI).

## Updating Configs

1. Edit files under this repo (e.g., `dot_zshrc`, `dot_config/nvim/init.lua`).
2. Run `chezmoi apply` to sync changes into `$HOME`.
3. Commit updates with descriptive messages and push to GitHub.

Use `chezmoi diff` to inspect changes before applying, and `chezmoi doctor` to verify templates on new hosts.

## License

MIT License © Ryan Caldwell
