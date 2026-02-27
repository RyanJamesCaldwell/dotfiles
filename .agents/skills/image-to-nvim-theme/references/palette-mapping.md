# Palette Mapping

Use this guide to convert sampled image colors into stable theme tokens.

## Role Targets

- `bg0`: main editor background.
- `bg1`: cursor line, floats, popup background.
- `bg2`: visual selection and subtle emphasis.
- `bg3`/`bg4`: borders, separators, line numbers.
- `fg0`: main foreground text.
- `fg1`: secondary text.
- `fg2`: comments/muted text.

## Accent Targets

- Primary accent family: keywords, statements, warnings, active UI states.
- Secondary accent family: strings, info/hints, function names, git adds.
- Utility accent: optional for constants, types, or diagnostics.

## Dark/Light Strategy

- `dark`: choose the darkest 10-20% image tones for `bg0` and keep contrast >= 4.5:1 against `fg0`.
- `light`: choose the lightest 10-20% image tones for `bg0`, but avoid pure white if possible.
- `both`: generate two modules (for example `<name>_night.lua` and `<name>_day.lua`) from one palette family.

## Practical Mapping

1. Sample 8-16 representative colors from dominant regions and accents.
2. Remove near-duplicates by visual distance.
3. Assign neutrals first (`bg*`, `fg*`), then accents.
4. Set `Search`/`IncSearch` and `PmenuSel` to high-contrast accents.
5. Ensure diagnostics are visually distinct:
   - error: warm/red family
   - warn: amber/pink family
   - info: blue/cyan family
   - hint: cool secondary family

## Minimum Highlight Coverage

Define or link at least these groups:
- Editor/UI: `Normal`, `NormalNC`, `LineNr`, `CursorLineNr`, `CursorLine`, `Visual`, `StatusLine`, `TabLineSel`.
- Syntax: `Comment`, `String`, `Number`, `Function`, `Keyword`, `Type`.
- Treesitter links: `@comment`, `@string`, `@function`, `@keyword`, `@type`, `@variable`.
- LSP: `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, virtual text, underlines.
- Git signs: `GitSignsAdd`, `GitSignsChange`, `GitSignsDelete`.
- Terminal: `terminal_color_0` through `terminal_color_15`.
