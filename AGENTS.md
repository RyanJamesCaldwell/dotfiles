# Repository Guidelines

## Project Structure & Module Organization
- Root dotfiles mirror their destination names: `dot_zshrc`, `dot_gitconfig`, and `Brewfile` provision the shell, git, and macOS packages.
- The Neovim setup lives in `dot_config/nvim`, with `init.lua` loading Kickstart defaults and local tweaks.
- Reusable Lua logic is grouped under `dot_config/nvim/lua/kickstart/`, while personal overrides stay in `dot_config/nvim/lua/custom/plugins/init.lua` so they are easy to extend or disable.
- Plugin state is pinned in `dot_config/nvim/lazy-lock.json`; update this file whenever plugin versions change to keep machines aligned.

## Build, Test, and Development Commands
- `chezmoi diff` — inspect pending template changes before applying them to your home directory.
- `chezmoi apply` — render the templates into place after you are satisfied with the diff.
- `brew bundle --file Brewfile` — sync Homebrew formulas and casks defined for this setup.
- `nvim --headless "+Lazy! sync" +qa` — validate that plugin specs resolve without interactive prompts after edits.

## Coding Style & Naming Conventions
- Lua files follow `dot_config/nvim/dot_stylua.toml`: two-space indentation, Unix line endings, and preferred single quotes; run `stylua --config-path dot_config/nvim/dot_stylua.toml dot_config/nvim/**/*.lua` before committing.
- Keep module names lowercase with words separated by underscores (e.g., `custom.plugins.lsp`), and mirror directory names when introducing new modules.
- For shell snippets in dotfiles, align indentation with two spaces and avoid trailing whitespace to prevent noisy diffs on target systems.

## Testing Guidelines
- After changing Neovim plugins or settings, run `nvim --headless "+checkhealth" +qa` on a clean terminal to surface runtime or dependency issues.
- Use `chezmoi doctor` when introducing new templates to confirm managed paths resolve correctly across hosts.
- If you touch the Brewfile, execute `brew bundle check --file Brewfile` to verify taps and packages are installable.

## Commit & Pull Request Guidelines
- Prefer short, imperative commit subjects under 60 characters (e.g., `Refine treesitter defaults`); add focused body notes only when extra context is required.
- Group related template and lockfile updates together so reviewers can replay `chezmoi diff` and plugin sync steps cleanly.
- For pull requests, include the command sequence you used to validate the change and mention any machine-specific considerations or follow-up tasks.

## Security & Configuration Tips
- Avoid hardcoding secrets or machine-only values; rely on `chezmoi secret` or local-only ignored files for sensitive data.
- Review generated configs on first apply to ensure hostnames, tokens, and SSH keys are referenced via environment variables instead of literal strings.
