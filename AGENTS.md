# Repository Guidelines

## Project Structure & Module Organization
- Root dotfiles mirror their destination names: `dot_zshrc.tmpl`, `dot_gitconfig`, and `Brewfile` provision the shell, git, and macOS packages.
- `install.sh` bootstraps both supported platforms. It dispatches on `uname -s`: macOS goes through Homebrew/`Brewfile`, Linux goes through apt plus a set of GitHub-release binaries installed into `~/.local/bin`. The Brewfile-to-apt parity table lives in a comment block above the Linux section of `install.sh`.
- `.github/scripts/verify-dotfiles.sh` asserts that a bootstrapped machine matches this repository; CI runs it on Ubuntu and it can be run locally on either platform.
- The Neovim setup lives in `dot_config/nvim`, with `init.lua` loading Kickstart defaults and local tweaks.
- Reusable Lua logic is grouped under `dot_config/nvim/lua/kickstart/`, while personal overrides stay in `dot_config/nvim/lua/custom/plugins/init.lua` so they are easy to extend or disable.
- Plugin state is pinned in `dot_config/nvim/lazy-lock.json`; update this file whenever plugin versions change to keep machines aligned.

## Cross-Platform Rules
- macOS is the reference platform. Any change to `dot_zshrc.tmpl` must keep the **rendered macOS output byte-identical** unless the change is explicitly about macOS.
- Platform differences are expressed with chezmoi conditionals on `.chezmoi.os` (`darwin` vs everything else), not with runtime `$OSTYPE` checks, so each machine gets a clean single-platform file.
- Use the `{{- if eq .chezmoi.os "darwin" }}` / `{{- else }}` / `{{- end }}` form (leading dash only). Trailing-dash trimming (`-}}`) also eats the indentation of the next line.
- Verify a template change by rendering `main` and your branch into throwaway destinations and diffing them:
  ```bash
  render() { # render <source-dir> <out-dir>
    rm -rf "$2"; mkdir -p "$2"/{home,cache,state}
    printf 'data:\n  profile: personal\n' > "$2/config.yaml"
    chezmoi --no-tty --source="$1" --destination="$2/home" --cache="$2/cache" \
      --persistent-state="$2/state/chezmoi.boltdb" --config="$2/config.yaml" \
      --refresh-externals=never apply --keep-going
  }
  git worktree add /tmp/dotfiles-main main
  render /tmp/dotfiles-main /tmp/render-before
  render "$PWD" /tmp/render-after
  diff -r -x .git /tmp/render-before/home /tmp/render-after/home
  ```
- Tools that only exist on macOS simply are not installed on Linux; the shell config must degrade gracefully rather than error at startup.


## Neovim Config Details (`dot_config/nvim/init.lua`)
- This is a single large file (~68 KB) containing all options, keymaps, and plugin specs — **do not explore the file with broad searches; use targeted Grep for specific sections**.
- Leader key is `<space>` (set at the top of `init.lua`).
- All keymaps use `vim.keymap.set(...)` and are organized by labeled comment sections in this order:
  - Basic mappings (`<Esc>` clears search, diagnostic quickfix)
  - Window splits (`<leader>-`, `<leader>|`)
  - Terminal mode escape
  - Window focus (`<C-h/j/k/l>`)
  - Buffer management (`<leader>b*`) — uses BufferLine
  - File explorer (`<leader>e/E`) — uses Neo-tree
  - Terminal (`<leader>ft`, `<C-/>`) — uses ToggleTerm
  - Better indenting (`<`/`>` in visual mode stay in visual mode)
  - JSON formatting (`<leader>jq` runs `:%!jq .`)
  - Quit (`<leader>q*`)
  - Git changed files helper (`<leader>gf`)
- To add a new keymap, append it to the appropriate labeled section in `init.lua`. No separate keymaps file exists.
- Custom plugins file (`lua/custom/plugins/init.lua`) is the right place for new plugin specs; kickstart plugins under `lua/kickstart/plugins/` should not be modified unless overriding upstream defaults.

## Build, Test, and Development Commands
- `chezmoi diff` — inspect pending template changes before applying them to your home directory.
- `chezmoi apply` — render the templates into place after you are satisfied with the diff.
- `./install.sh` — bootstrap a machine (macOS or Debian/Ubuntu). `./install.sh --minimal` skips GUI apps, fonts, language-runtime managers, and heavy services.
- `brew bundle --file Brewfile` — sync Homebrew formulas and casks defined for this setup (macOS only).
- `.github/scripts/verify-dotfiles.sh` — assert the applied configuration is correct on the current machine.
- `nvim --headless "+Lazy! sync" +qa` — validate that plugin specs resolve without interactive prompts after edits.

## Coding Style & Naming Conventions
- Lua files follow `dot_config/nvim/dot_stylua.toml`: two-space indentation, Unix line endings, and preferred single quotes; run `stylua --config-path dot_config/nvim/dot_stylua.toml dot_config/nvim/**/*.lua` before committing.
- Keep module names lowercase with words separated by underscores (e.g., `custom.plugins.lsp`), and mirror directory names when introducing new modules.
- For shell snippets in dotfiles, align indentation with two spaces and avoid trailing whitespace to prevent noisy diffs on target systems.

## Testing Guidelines
- Before running runtime checks for managed dotfiles, confirm whether `chezmoi apply` has been run; if not, label runtime output as stale-home-config and treat static repo checks as authoritative.
- After changing Neovim plugins or settings, run `nvim --headless "+checkhealth" +qa` on a clean terminal to surface runtime or dependency issues.
- After changing `dot_zshrc`/`dot_zshrc.tmpl`, include a reload step in validation instructions (`source ~/.zshrc` or `exec zsh`) before testing shell functions.
- Use `chezmoi doctor` when introducing new templates to confirm managed paths resolve correctly across hosts.
- If you touch the Brewfile, execute `brew bundle check --file Brewfile` to verify taps and packages are installable.
- Formulae from non-official taps (`oven-sh/bun`, `stripe/stripe-cli`) need `trusted: true` on their `brew` line, otherwise Homebrew refuses to load them and `brew bundle` aborts. `brew bundle` grants the trust itself, so `brew bundle check` may still warn about them until an install has run once on a fresh machine. To exercise a trust change without touching your real trust store, point `XDG_CONFIG_HOME` at a throwaway directory:
  ```bash
  XDG_CONFIG_HOME="$(mktemp -d)" brew bundle install --no-upgrade --file Brewfile
  ```
- If you touch `install.sh` or anything it installs, exercise the Linux path end to end in a throwaway container before relying on CI:
  ```bash
  docker run --rm -it -v "$PWD:/src:ro" ubuntu:24.04 bash -lc '
    apt-get update -qq && apt-get install -y -qq sudo git curl ca-certificates >/dev/null
    useradd -m -s /bin/bash tester && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester
    cp -a /src /home/tester/dotfiles && chown -R tester /home/tester/dotfiles
    su - tester -c "cd ~/dotfiles && ./install.sh --minimal && .github/scripts/verify-dotfiles.sh ~/dotfiles"'
  ```
- CI covers both platforms: the `validate` job does static checks on macOS, and `bootstrap-ubuntu` runs `./install.sh --minimal` twice on `ubuntu-latest` and then `verify-dotfiles.sh`.

## Agent Workflow
- When a task explicitly invokes a skill, read that skill's required-input checklist and collect any missing required inputs before making edits.
- For `image-to-nvim-theme`, confirm all required inputs up front: mode (`light|dark|both`), module token, and whether to set it as default now.

## Commit & Pull Request Guidelines
- Prefer short, imperative commit subjects under 60 characters (e.g., `Refine treesitter defaults`); add focused body notes only when extra context is required.
- Group related template and lockfile updates together so reviewers can replay `chezmoi diff` and plugin sync steps cleanly.
- For pull requests, include the command sequence you used to validate the change and mention any machine-specific considerations or follow-up tasks.

## Security & Configuration Tips
- Avoid hardcoding secrets or machine-only values; rely on `chezmoi secret` or local-only ignored files for sensitive data.
- Review generated configs on first apply to ensure hostnames, tokens, and SSH keys are referenced via environment variables instead of literal strings.
