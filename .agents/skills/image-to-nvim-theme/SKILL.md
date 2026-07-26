---
name: image-to-nvim-theme
description: Create image-driven themes that stay synchronized across Neovim, Starship, and zsh by extracting a palette, generating theme files, and wiring shared runtime switching. Use when a user shares artwork, screenshots, photos, or mood boards and asks for a custom terminal/editor theme.
---

# Image To Nvim Theme

## Overview

Turn an image into a usable theme set and integrate it with the existing shared
theme workflow (`~/.config/theme/current`). A theme is one token that drives
Neovim, Starship/zsh and WezTerm together. Preserve existing themes and add the
new one as an option everywhere.

The Starship and Neovim files are **generated** from a palette in
`tools/gen-themes.py` — you write a palette, not two theme files. See
`AGENTS.md` for the same contract stated repo-wide.

## Workflow

### 1. Gather inputs

Ask for missing requirements before editing:
- Ask `light`, `dark`, or `both`. Note the generator's palettes are dark-only
  today; a light theme needs the palette roles inverted deliberately.
- Default to `dark` if the user does not specify.
- Ask for a module name if missing (for example `nightshade`).
- Ask whether the new theme should become default now; otherwise keep current default unchanged.
- Use one exact theme token (`<module>`) across all files (Neovim, zsh, Starship, WezTerm) with no aliases.

### 2. Extract palette and assign roles

Sample the image and define, in the key names `tools/gen-themes.py` expects:
- 5 background steps (`bg0`..`bg4`) — `bg0` is the base
- 4 foreground steps (`fg0`..`fg3`) — `fg3` is comments
- 3 accents (`accent`, `accent2`, `accent3`)
- 5 syntax hues (`str`, `num`, `kw`, `fn`, `typ`) plus `spec`
- diagnostics (`err`, `warn`, `info`, `hint`) and git (`add`, `change`, `del`)
- a 16-colour `term` ramp: black, red, green, yellow, blue, magenta, cyan, white, then the same eight brightened

Two rules are load-bearing, not stylistic. Themes that broke either have been
tried in this repo and rejected as unreadable:
- **`bg0` must be softly tinted, around `#1a1324` in lightness — never near-black.**
- **`str`/`num`/`kw`/`fn`/`typ` must be five clearly different hues.** A palette
  that collapses syntax onto one or two hues reads as flat.

Most images will not supply eight distinct ANSI hues, so expect to synthesise a
magenta and a cyan that sit in the same family as the sampled colours.

Use [palette-mapping.md](references/palette-mapping.md) to map image colors into semantic roles.

### 3. Add the palette to the generator

**Do not hand-write theme files.** `dot_config/starship/themes/<module>.toml` and
`dot_config/nvim/lua/custom/<module>.lua` are generated output; editing them
directly is reverted by the next generator run and fails CI in the meantime.

Instead add one entry to `PALETTES` in `tools/gen-themes.py` and run it:

```bash
./tools/gen-themes.py            # writes both files for every theme
./tools/gen-themes.py --check    # what CI runs; asserts nothing is stale
```

Notes on the palette entry:
- Include a one-line `desc`; it becomes the header comment in both files.
- Only `dir`, `rule` and `clock` are prompt-specific. Every other prompt colour
  is derived from the editor palette via `PROMPT_FROM_PALETTE`, so define each
  colour once. Omit the optional `prompt` block to get blended defaults, or
  supply it to hand-tune the path, fill rule and clock.
- The prompt silhouette is shared by all themes on purpose: switching themes
  should change colour, not layout. Do not add per-theme modules or formats.

### 4. Wire switching without removing existing themes

The generator writes the two theme files; the four registration points below are
hand-edited. Keep all current themes.

- `dot_config/nvim/init.lua`: append the module name to the `theme_order` table.
  That single list drives `valid_themes`, `apply_theme`, the `ThemeSet`
  validation/completion/description, and the `ThemeToggle` cycle, so nothing
  else in that file needs editing. Only add to `plugin_colorschemes` if the
  theme is served by an installed plugin instead of a `lua/custom/` module.
- `dot_zshrc.tmpl`: append the module name to the `THEME_CHOICES` array.
  `_set_starship_config_for_theme` derives the path as
  `$STARSHIP_THEME_DIR/<module>.toml`, so there is no case arm to extend; the
  name just has to be in `THEME_CHOICES` and the file has to exist.
- `dot_wezterm.lua`: run `./tools/gen-themes.py --wezterm <module>` and paste
  the two printed blocks into `custom_color_schemes` and `theme_spec`. They
  reuse the Neovim module's 16-colour `term` ramp verbatim so `:terminal` and a
  bare WezTerm pane match; `--check` verifies they have not drifted.
- `.github/scripts/verify-dotfiles.sh`: add the name to `THEME_FAMILY` (or
  `ALL_THEMES` for a plugin-backed theme). The loops read those variables.
- `README.md`: add a row to the theme table.
- Set default theme only if the user requests it. The default is the first entry
  of `theme_order` / `THEME_CHOICES` and `default_theme` in `dot_wezterm.lua`.
- Do not introduce a second source of truth; keep `~/.config/theme/current` as the only persisted state.

### 5. Retiring a theme

Deleting a theme means removing its `PALETTES` entry, running the generator,
deleting the two now-orphaned files, and unregistering the name from all five
places above. Note that `chezmoi apply` is additive: it will not remove the old
files from `$HOME`, so delete those by hand.

### 6. Validate changes (required)

Run fast checks:
- `./tools/gen-themes.py --check`
- `python3 .agents/skills/image-to-nvim-theme/scripts/quick_validate.py .agents/skills/image-to-nvim-theme`
- `stylua --config-path dot_config/nvim/dot_stylua.toml --check dot_config/nvim/lua/custom/<module>.lua`
- `zsh -n` on the **rendered** zshrc, not the template: `zsh -n dot_zshrc.tmpl` always
  fails because chezmoi `{{ }}` actions are not valid zsh. Render first (see the
  render helper in `AGENTS.md`) and run `zsh -n <out-dir>/home/.zshrc`.
- `STARSHIP_CONFIG=dot_config/starship/themes/<module>.toml starship print-config >/dev/null`
- Render the prompt to eyeball it. `STARSHIP_SHELL` must name a real shell or
  Starship silently skips custom modules; `sh` also avoids zsh's `%{...%}`
  escapes:
  `STARSHIP_SHELL=sh STARSHIP_CONFIG=dot_config/starship/themes/<module>.toml starship prompt --status=130 --cmd-duration=3400 --jobs=1 --terminal-width=100`
- Load the colorscheme for real. A Lua syntax check still passes on arguments
  that `nvim_set_hl` rejects:
  `nvim --headless --clean --cmd "set runtimepath+=$PWD/dot_config/nvim" -c "lua require('custom.<module>').setup()" -c 'quitall!'`
- `.github/scripts/verify-dotfiles.sh "$PWD"` after `chezmoi apply` — asserts the
  name resolves in Starship, WezTerm and Neovim at once.
- Optional runtime checks:
  - `nvim --headless "+ThemeSet <module>" "+qa"`
  - `zsh -ic 'theme <module>; echo $NVIM_THEME; echo $STARSHIP_CONFIG'`

Hard requirement: do not finish until static validation passes and every integration point above is present in all three files.

If an environment tool is missing (for example `stylua`), report it and continue with available validation.

### 7. Return actionable usage

Always provide:
- File paths changed.
- Theme commands to test (`:ThemeSet <name>`, `:ThemeToggle`, `theme <name>`).
- Any default-theme change made.
- Validation results and limitations.

## Implementation Notes

- Prefer low-risk iterative tuning over perfect first-pass palettes. Tuning is
  cheap here: edit the palette, re-run the generator, re-render the prompt.
- Avoid pure black and pure white unless user explicitly asks. `bg0` near-black
  and a white `fg0` are the two failure modes this theme family was rebuilt to
  escape.
- Maintain readable contrast on `Normal`, `Comment`, `CursorLineNr`, diagnostics, and selection states.
- Preserve user-owned config patterns; do not remove unrelated theme code.
- Keep every theme glyph-free. The prompt uses ASCII and words so it renders
  identically without a Nerd Font, and so `git diff` on a theme file stays
  reviewable.

## References

- [palette-mapping.md](references/palette-mapping.md): practical mapping from sampled image colors to Neovim highlight roles.
