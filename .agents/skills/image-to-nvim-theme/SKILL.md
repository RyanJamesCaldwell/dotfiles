---
name: image-to-nvim-theme
description: Create image-driven themes that stay synchronized across Neovim, Starship, and zsh by extracting a palette, generating theme files, and wiring shared runtime switching. Use when a user shares artwork, screenshots, photos, or mood boards and asks for a custom terminal/editor theme.
---

# Image To Nvim Theme

## Overview

Turn an image into a usable theme set and integrate it with the existing shared theme workflow (`~/.config/theme/current`). Preserve existing themes and add the new one as an option everywhere: Neovim, Starship, and zsh theme commands.

## Workflow

### 1. Gather inputs

Ask for missing requirements before editing:
- Ask `light`, `dark`, or `both`.
- Default to `dark` if the user does not specify.
- Ask for a module name if missing (for example `sakura_night`).
- Ask whether the new theme should become default now; otherwise keep current default unchanged.
- Use one exact theme token (`<module>`) across all files (Neovim, zsh, Starship) with no aliases.

### 2. Extract palette and assign roles

Sample the image and define:
- 4-5 background steps (`bg0`..`bg4`)
- 2-3 foreground steps (`fg0`..`fg2`)
- 2 accent families (primary + secondary, 3-4 shades each)
- 1-2 utility tones (`mist`, `lavender`, `muted`, etc.)

Use [palette-mapping.md](references/palette-mapping.md) to map image colors into semantic roles.

### 3. Implement Neovim theme module

Create `dot_config/nvim/lua/custom/<module>.lua`:
- Follow the structure used by `custom/ashfall.lua` for consistency.
- Set `vim.g.colors_name` to the module name.
- Define editor, syntax, treesitter links, diagnostics, git signs, and terminal colors.
- Keep backgrounds dark when mode is `dark` or when defaulting.
- Use single quotes and two-space indentation when possible.

### 4. Implement Starship theme file

Create `dot_config/starship/themes/<module>.toml`:
- Copy structure from an existing theme file (for example `dot_config/starship/themes/sakura_night.toml`) and only swap color values.
- Keep module sections and prompt format consistent (`character`, `directory`, `git_branch`, `git_metrics`, `custom.chezmoi`, language modules, `time`).
- Keep the file ASCII and valid TOML.

### 5. Wire switching without removing existing themes

Update the existing theme selection logic:
- Keep all current themes.
- Add the new theme to `dot_config/nvim/init.lua` in all theme-control points:
  - `valid_themes` table.
  - `apply_theme(theme)` branch (`require('custom.<module>').setup()` + `save_theme('<module>')`).
  - `ThemeSet` validation, completion list, and command description text.
  - `ThemeToggle` cycle order and description text.
- Add the new theme to `dot_zshrc.tmpl` in all theme-control points:
  - `_set_starship_config_for_theme` case arm mapping to `$STARSHIP_THEME_DIR/<module>.toml`.
  - `_sync_theme_from_state` allowed theme case list.
  - `theme()` usage/help text, validation case list, and "Valid themes" output.
- Set default theme only if the user requests it.
- Do not introduce a second source of truth; keep `~/.config/theme/current` as the only persisted state.

### 6. Validate changes (required)

Run fast checks:
- `python3 skills/image-to-nvim-theme/scripts/quick_validate.py skills/image-to-nvim-theme`
- `luac -p dot_config/nvim/lua/custom/<module>.lua`
- `zsh -n dot_zshrc.tmpl`
- `test -f dot_config/starship/themes/<module>.toml`
- `rg -n "<module>" dot_config/nvim/init.lua dot_zshrc.tmpl dot_config/starship/themes/<module>.toml`
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

- Prefer low-risk iterative tuning over perfect first-pass palettes.
- Avoid pure black and pure white unless user explicitly asks.
- Maintain readable contrast on `Normal`, `Comment`, `CursorLineNr`, diagnostics, and selection states.
- Preserve user-owned config patterns; do not remove unrelated theme code.

## References

- [palette-mapping.md](references/palette-mapping.md): practical mapping from sampled image colors to Neovim highlight roles.
