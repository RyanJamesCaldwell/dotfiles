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

`oven-sh/bun` and `stripe/stripe-cli` are third-party taps, and Homebrew refuses to load formulae from non-official taps unless they are trusted. Their `Brewfile` entries carry `trusted: true`, so `brew bundle` records the trust before installing and no manual `brew trust` step is needed.

## Highlights

- **Shell**: Zsh with oh-my-zsh, fzf integration, starship prompt, lazy nvm/asdf loading, aliases tuned for git, and `wt` sourced from `~/.config/wt/wt.zsh`.
- **Editor**: Kickstart-based Neovim setup with Stylua formatting and lazily-loaded plugins.
- **Terminal**: WezTerm configuration for pane-focused workflows, rose-pine colors, and JetBrainsMono Nerd Font.
- **Packages**: Brewfile defines CLI tools (asdf, gh, ripgrep, etc.) and GUI apps (WezTerm, ngrok, 1Password CLI).

## Theming

A theme is one word that repaints everything: the Starship prompt, Neovim, and
WezTerm all follow `~/.config/theme/current`.

| Theme | Look |
| --- | --- |
| `nightshade` | Default. Deep plum under mint, gold and lilac |
| `aurora` | Cold navy sky lit by pastel green, pink and ice blue |
| `abyss` | Deep water. Teal-navy with aqua, coral and seafoam |
| `rosepine` | Rosé Pine Moon |

The first three are cut from one template, so they share an identical
prompt silhouette and highlight set — switching between them changes colour
without moving anything. Each pairs a softly tinted (never near-black) base with
five distinct pastel hues, so syntax stays legible at low contrast:

```
~/dev/dotfiles main +234 -29 lua v5.4.7 ──────────── jobs 2 ×130 12s 23:39
❯
```

Identity and context sit on the left, a hairline rule pushes transient state
(failed exit codes, background jobs, command duration, clock) to the right edge,
and the second line holds nothing but the caret. Git is reduced to the branch
plus the working-tree churn (`+234 -29`) rather than a row of per-file status
flags, and there are no devicons at all, so the prompt reads the same over a
plain SSH session or in any terminal without a patched font.

- **From the shell**:
  - `theme` or `theme current` shows the active theme
  - `theme list` lists every name
  - `theme preview` renders each prompt inline so you can compare them
  - `theme pick` opens an fzf picker, with a numbered fallback
  - `theme <name>` applies a theme
- **From Neovim**: `:ThemeSet <name>` (with completion) or `:ThemeToggle` to cycle
- **From WezTerm**: reads the state file and restyles automatically, within ~1s

Changes are persisted, and every already-open shell picks them up on its next
prompt, so switching in one window follows you everywhere.

Adding a theme means writing a palette, not writing theme files. The Starship
`.toml` and the Neovim Lua module are generated from a single palette in
[`tools/gen-themes.py`](tools/gen-themes.py) — run it with no arguments to
regenerate, `--check` to assert nothing is stale (CI does this), and
`--wezterm <name>` to print the WezTerm blocks. `AGENTS.md` has the full
contract.

Theme files live in:

- `dot_config/starship/themes/<name>.toml` for the prompt
- `dot_config/nvim/lua/custom/<name>.lua` for the editor
- `dot_wezterm.lua` for the terminal palette and tab bar

Adding a theme means touching all three plus `THEME_CHOICES` in `dot_zshrc.tmpl`
and `theme_order` in `dot_config/nvim/init.lua`; `verify-dotfiles.sh` asserts
that every registered name resolves in each place. Those three also share
their 16-colour ramp between the Neovim `:terminal` palette and the WezTerm
scheme, so a shell inside the editor matches a bare terminal pane exactly.

`azure` is disabled in these themes because subscription display names are
long enough to swamp the prompt; set `disabled = false` in the theme file to opt
back in.

## Updating Configs

1. Edit files under this repo (e.g., `dot_zshrc.tmpl`, `dot_config/nvim/init.lua`).
2. Run `chezmoi apply` to sync changes into `$HOME`.
3. Commit updates with descriptive messages and push to GitHub.

Use `chezmoi diff` to inspect changes before applying, and `chezmoi doctor` to verify templates on new hosts.

## Verifying an Install

`.github/scripts/verify-dotfiles.sh` checks that a bootstrapped machine matches this repository: managed files exist, the platform-specific `~/.zshrc` rendered correctly, core commands resolve, `chezmoi verify` reports no drift, every Starship theme parses, every theme resolves in Starship, WezTerm and Neovim alike, and an interactive Zsh exposes the `theme`/`profile`/`wt` helpers.

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
