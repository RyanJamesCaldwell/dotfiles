#!/usr/bin/env python3
"""Generate the shared dark theme family.

A theme here is not a colour scheme for one program: it is a Starship prompt, a
Neovim colorscheme and a WezTerm palette that must agree with each other. This
script is the single source of truth for all three, so they cannot drift.

    tools/gen-themes.py              # rewrite every generated theme file
    tools/gen-themes.py --check      # fail if the committed files are stale
    tools/gen-themes.py --wezterm X  # print the Lua blocks for dot_wezterm.lua

Adding a theme
--------------
1. Add an entry to PALETTES below. The design rules are not decoration:
   a tinted background (never near-black) and five clearly different pastel
   hues for str/num/kw/fn/typ are what keep these themes readable.
2. Run this script with no arguments.
3. Register the name in the four places the generator cannot reach:
   THEME_CHOICES in dot_zshrc.tmpl, theme_order in dot_config/nvim/init.lua,
   both tables in dot_wezterm.lua (use --wezterm), and the README table.
4. Run .github/scripts/verify-dotfiles.sh, which asserts the name resolves
   everywhere.

Nerd Fonts are deliberately avoided: every symbol emitted here is ASCII or a
common Unicode box-drawing/arrow character, so the prompt survives a plain SSH
session on a machine with no patched font.
"""

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
STARSHIP_DIR = REPO_ROOT / "dot_config" / "starship" / "themes"
NVIM_DIR = REPO_ROOT / "dot_config" / "nvim" / "lua" / "custom"
WEZTERM_FILE = REPO_ROOT / "dot_wezterm.lua"

# --- palettes ---------------------------------------------------------------
# One palette per theme, in the order they should appear in THEME_CHOICES.
# The Neovim keys below are the source of truth; the prompt palette is derived
# from them by PROMPT_FROM_PALETTE, so a colour is only ever written once.

PALETTES = {
    "nightshade": {
        "desc": "Deep plum under a soft pastel foreground.",
        "bg0": "#1a1324", "bg1": "#221a2e", "bg2": "#2d2340", "bg3": "#3a2e51", "bg4": "#4b3d68",
        "fg0": "#f2eaf8", "fg1": "#d6c9e6", "fg2": "#a294b8", "fg3": "#7a6c90",
        "accent": "#c7a9f0", "accent2": "#eba8c8", "accent3": "#9d7fd0",
        "str": "#a3dcc0", "num": "#e9cf9e", "kw": "#c7a9f0", "fn": "#a6c6ee", "typ": "#eba8c8", "spec": "#e9cf9e",
        "err": "#f08a9c", "warn": "#e9cf9e", "info": "#a6c6ee", "hint": "#a3dcc0",
        "add": "#a3dcc0", "change": "#e9cf9e", "del": "#f08a9c",
        "term": [
            "#2d2340", "#f08a9c", "#a3dcc0", "#e9cf9e", "#a6c6ee", "#c7a9f0", "#8fd6e8", "#d6c9e6",
            "#4b3d68", "#f4a3b2", "#b8e8cf", "#f2dcb4", "#bcd6f4", "#eba8c8", "#a8e2f0", "#f2eaf8",
        ],
        # Hand-tuned prompt colours; omit this block to use blended defaults.
        "prompt": {"dir": "#dcc9f2", "rule": "#332843", "clock": "#8b7ea1"},
    },
    "aurora": {
        "desc": "Cold night sky lit by pastel greens, pinks and ice blues.",
        "bg0": "#0f1620", "bg1": "#151e2b", "bg2": "#1e2a3a", "bg3": "#2a394d", "bg4": "#3b4d66",
        "fg0": "#eaf2fa", "fg1": "#cbdcec", "fg2": "#93a8c0", "fg3": "#6b7f96",
        "accent": "#a8b4f0", "accent2": "#f0a8d8", "accent3": "#7986d0",
        "str": "#8fe6c0", "num": "#f0d9a0", "kw": "#a8b4f0", "fn": "#8fd8f0", "typ": "#f0a8d8", "spec": "#f0d9a0",
        "err": "#f28ba8", "warn": "#f0d9a0", "info": "#8fd8f0", "hint": "#8fe6c0",
        "add": "#8fe6c0", "change": "#f0d9a0", "del": "#f28ba8",
        "term": [
            "#1e2a3a", "#f28ba8", "#8fe6c0", "#f0d9a0", "#a8b4f0", "#f0a8d8", "#8fd8f0", "#cbdcec",
            "#3b4d66", "#f5a3ba", "#a8f0d0", "#f5e4b8", "#bcc4f5", "#f5bce4", "#a8e4f5", "#eaf2fa",
        ],
        # Hand-tuned prompt colours; omit this block to use blended defaults.
        "prompt": {"dir": "#d5e4f5", "rule": "#232f40", "clock": "#8195ab"},
    },
    "abyss": {
        "desc": "Deep water. Teal-navy base with aqua, coral and seafoam.",
        "bg0": "#101c24", "bg1": "#16252f", "bg2": "#1e313e", "bg3": "#2a4150", "bg4": "#395667",
        "fg0": "#e8f4f8", "fg1": "#c5dce6", "fg2": "#8fa9b8", "fg3": "#667e8c",
        "accent": "#7fd4d4", "accent2": "#f0a898", "accent3": "#4f9aa8",
        "str": "#9ae0c0", "num": "#f2cf9c", "kw": "#7fd4d4", "fn": "#a9c4f0", "typ": "#f0a898", "spec": "#f2cf9c",
        "err": "#f58b8b", "warn": "#f2cf9c", "info": "#a9c4f0", "hint": "#9ae0c0",
        "add": "#9ae0c0", "change": "#f2cf9c", "del": "#f58b8b",
        "term": [
            "#1e313e", "#f58b8b", "#9ae0c0", "#f2cf9c", "#a9c4f0", "#e0a8d8", "#7fd4d4", "#c5dce6",
            "#395667", "#f7a3a3", "#b0e8ce", "#f5dab4", "#bcd4f5", "#eabce4", "#9ae0e0", "#e8f4f8",
        ],
        # Hand-tuned prompt colours; omit this block to use blended defaults.
        "prompt": {"dir": "#cfe6ee", "rule": "#24333f", "clock": "#7d94a3"},
    },
}

# The prompt reuses the editor's colours rather than defining its own, which is
# what makes a theme feel like one theme instead of three coincidences.
PROMPT_FROM_PALETTE = {
    "dir_dim": "fg3", "branch": "accent", "gitstate": "num", "gitadd": "str",
    "gitdel": "err", "lang": "fn", "lang_dim": "fg3", "ctx": "fg2",
    "ctx_dim": "fg3", "err": "err", "dur": "num", "caret": "accent",
    "caret_err": "err", "vim": "str",
}

# Emitted in this order so a diff between two theme files lines up.
PROMPT_KEY_ORDER = [
    "dir", "dir_dim", "branch", "gitstate", "gitadd", "gitdel",
    "lang", "lang_dim", "ctx", "ctx_dim", "rule", "err", "dur", "clock",
    "caret", "caret_err", "vim",
]


def _blend(a: str, b: str) -> str:
    """Midpoint of two #rrggbb colours."""
    pair = [(int(a[i:i + 2], 16) + int(b[i:i + 2], 16)) // 2 for i in (1, 3, 5)]
    return "#{:02x}{:02x}{:02x}".format(*pair)


def prompt_palette(name: str) -> dict:
    """Build the Starship palette for one theme.

    Three colours have no editor equivalent: the path (deliberately the most
    saturated thing on the line), the fill rule and the clock. A theme may tune
    them explicitly; otherwise they are blended from neighbouring shades.
    """
    pal = PALETTES[name]
    tuned = pal.get("prompt", {})
    out = {key: pal[src] for key, src in PROMPT_FROM_PALETTE.items()}
    out["dir"] = tuned.get("dir") or _blend(pal["fg0"], pal["accent"])
    out["rule"] = tuned.get("rule") or _blend(pal["bg2"], pal["bg3"])
    out["clock"] = tuned.get("clock") or _blend(pal["fg2"], pal["fg3"])
    return out


TQ = '"' * 3

STARSHIP_BODY = """
add_newline = true
command_timeout = 1000
palette = "@name@"

# Line 1: identity and context, left aligned.
# A hairline fill pushes transient state (failures, timing, clock) to the right
# edge, so the eye always finds the same information in the same place.
# Line 2: nothing but the caret, to keep typed commands on a clean margin.
format = @tq@
$username\\
$hostname\\
$directory\\
$git_branch\\
$git_state\\
$git_metrics\\
$nodejs\\
$python\\
$golang\\
$rust\\
$java\\
$lua\\
$ruby\\
$php\\
$package\\
$docker_context\\
$kubernetes\\
$aws\\
$fill\\
$jobs\\
$status\\
$cmd_duration\\
$time\\
$line_break\\
$character\\
@tq@

# --- left: identity ---------------------------------------------------------

[username]
show_always = false
format = "[$user](ctx)[@](rule)"
style_user = "ctx"
style_root = "bold err"

[hostname]
ssh_only = true
format = "[$hostname](ctx) "

[directory]
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold dir"
truncation_length = 3
truncation_symbol = "…/"
truncate_to_repo = true
read_only = " ro"
read_only_style = "dir_dim"

# --- left: git --------------------------------------------------------------

[git_branch]
symbol = ""
format = "[$branch](branch) "
truncation_length = 24
truncation_symbol = "…"

[git_state]
format = "[$state( $progress_current/$progress_total)](bold gitstate) "
rebase = "rebase"
merge = "merge"
revert = "revert"
cherry_pick = "cherry-pick"
bisect = "bisect"
am = "am"
am_or_rebase = "am/rebase"

# Per-line churn, which is the number that actually tells you how big the
# working change is.
[git_metrics]
disabled = false
only_nonzero_diffs = true
added_style = "gitadd"
deleted_style = "gitdel"
format = "([+$added]($added_style) )([-$deleted]($deleted_style) )"

# --- left: toolchain --------------------------------------------------------
# Word labels instead of devicons: they survive any font and read faster.

[nodejs]
symbol = "node "
format = "([$symbol](lang)[$version](lang_dim) )"

[python]
symbol = "py "
format = "([$symbol](lang)[$version](lang_dim)[( $virtualenv)](ctx_dim) )"

[golang]
symbol = "go "
format = "([$symbol](lang)[$version](lang_dim) )"

[rust]
symbol = "rs "
format = "([$symbol](lang)[$version](lang_dim) )"

[java]
symbol = "java "
format = "([$symbol](lang)[$version](lang_dim) )"

[lua]
symbol = "lua "
format = "([$symbol](lang)[$version](lang_dim) )"

[ruby]
symbol = "rb "
format = "([$symbol](lang)[$version](lang_dim) )"

[php]
symbol = "php "
format = "([$symbol](lang)[$version](lang_dim) )"

[package]
symbol = "pkg "
display_private = true
format = "([$symbol](lang)[$version](lang_dim) )"

# --- left: deployment context ----------------------------------------------

[docker_context]
symbol = "docker "
only_with_files = true
format = "([$symbol](ctx)[$context](ctx_dim) )"

# Scoped to repositories that actually contain manifests, so it costs nothing
# in an ordinary directory.
[kubernetes]
disabled = false
symbol = "k8s "
format = "([$symbol](ctx)[$context](ctx_dim)[( $namespace)](ctx_dim) )"
detect_files = ["Chart.yaml", "skaffold.yaml", "kustomization.yaml"]
detect_folders = ["k8s", "kubernetes", "manifests", "helm"]

[aws]
symbol = "aws "
format = "([$symbol](ctx)[$profile](ctx_dim) )"

# Azure subscription display names are long enough to swamp the prompt
# ("Visual Studio Enterprise Subscription" is 37 characters), so it stays off.
[azure]
disabled = true

# --- the rule ---------------------------------------------------------------

[fill]
symbol = "─"
style = "rule"

# --- right: transient state -------------------------------------------------

[jobs]
symbol = "jobs "
number_threshold = 1
format = "( [$symbol](ctx)[$number](ctx_dim))"

[status]
disabled = false
symbol = "×"
format = " [$symbol$status](bold err)"
map_symbol = false
pipestatus = true
pipestatus_separator = "[|](rule)"
pipestatus_format = " [$symbol$pipestatus](bold err)"

# The character module already appends a trailing space via its own
# format ("$symbol "), so the symbols below must not carry one.

[cmd_duration]
min_time = 500
show_milliseconds = false
format = " [$duration](dur)"

[time]
disabled = false
format = " [$time](clock)"
time_format = "%H:%M"

[character]
success_symbol = "[❯](caret)"
error_symbol = "[❯](caret_err)"
vimcmd_symbol = "[❮](vim)"
vimcmd_replace_one_symbol = "[❮](gitstate)"
vimcmd_replace_symbol = "[❮](gitstate)"
vimcmd_visual_symbol = "[❮](gitadd)"
"""

NVIM_KEY_ORDER = [
    ("bg0", "base background"),
    ("bg1", "panels, cursor line"),
    ("bg2", "selection, popup menus"),
    ("bg3", "borders, line numbers"),
    ("bg4", "dim UI"),
    ("fg0", "brightest text"),
    ("fg1", "normal text"),
    ("fg2", "muted text"),
    ("fg3", "comments"),
    ("accent", "primary"),
    ("accent2", "secondary"),
    ("accent3", "deep"),
    ("str", "strings"),
    ("num", "numbers, constants"),
    ("kw", "keywords"),
    ("fn", "functions"),
    ("typ", "types"),
    ("spec", "special"),
    ("err", "error"),
    ("warn", "warning"),
    ("info", "info"),
    ("hint", "hint"),
    ("add", "git add"),
    ("change", "git change"),
    ("del", "git delete"),
]

NVIM_TEMPLATE = """-- @name@ - @desc@
-- Generated: keep the whole family in step rather than editing one file by hand.
local M = {}

local c = {
@palette@
}

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(from, to)
  vim.api.nvim_set_hl(0, from, { link = to })
end

function M.setup()
  vim.opt.termguicolors = true
  vim.opt.background = 'dark'

  vim.cmd 'highlight clear'
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
  vim.g.colors_name = '@name@'

  -- Editor chrome
  hl('Normal', { fg = c.fg1, bg = c.bg0 })
  hl('NormalNC', { fg = c.fg1, bg = c.bg0 })
  hl('NormalFloat', { fg = c.fg1, bg = c.bg1 })
  hl('FloatBorder', { fg = c.bg4, bg = c.bg1 })
  hl('FloatTitle', { fg = c.accent, bg = c.bg1, bold = true })
  hl('EndOfBuffer', { fg = c.bg0, bg = c.bg0 })
  hl('SignColumn', { fg = c.fg2, bg = c.bg0 })
  hl('Folded', { fg = c.fg2, bg = c.bg1 })
  hl('FoldColumn', { fg = c.bg4, bg = c.bg0 })
  hl('Conceal', { fg = c.bg4 })
  hl('Directory', { fg = c.accent })
  hl('Title', { fg = c.accent, bold = true })
  hl('WinBar', { fg = c.fg2, bg = c.bg0 })
  hl('WinBarNC', { fg = c.fg3, bg = c.bg0 })

  hl('LineNr', { fg = c.bg4, bg = c.bg0 })
  hl('CursorLineNr', { fg = c.accent, bg = c.bg1, bold = true })
  hl('CursorLine', { bg = c.bg1 })
  hl('CursorColumn', { bg = c.bg1 })
  hl('ColorColumn', { bg = c.bg1 })
  hl('Whitespace', { fg = c.bg3 })
  hl('NonText', { fg = c.bg3 })
  hl('SpecialKey', { fg = c.bg4 })
  hl('MatchParen', { fg = c.accent2, bg = c.bg3, bold = true })

  hl('WinSeparator', { fg = c.bg3, bg = c.bg0 })
  hl('VertSplit', { fg = c.bg3, bg = c.bg0 })

  hl('Visual', { bg = c.bg3 })
  hl('VisualNOS', { bg = c.bg3 })
  hl('Search', { fg = c.bg0, bg = c.accent })
  hl('IncSearch', { fg = c.bg0, bg = c.accent2, bold = true })
  hl('CurSearch', { fg = c.bg0, bg = c.accent2, bold = true })
  hl('Substitute', { fg = c.bg0, bg = c.change })

  hl('Pmenu', { fg = c.fg1, bg = c.bg2 })
  hl('PmenuSel', { fg = c.fg0, bg = c.bg4, bold = true })
  hl('PmenuSbar', { bg = c.bg2 })
  hl('PmenuThumb', { bg = c.bg4 })
  hl('PmenuKind', { fg = c.typ, bg = c.bg2 })
  hl('PmenuKindSel', { fg = c.typ, bg = c.bg4 })
  hl('PmenuExtra', { fg = c.fg3, bg = c.bg2 })
  hl('PmenuExtraSel', { fg = c.fg2, bg = c.bg4 })
  hl('WildMenu', { fg = c.bg0, bg = c.accent })

  hl('StatusLine', { fg = c.fg1, bg = c.bg2 })
  hl('StatusLineNC', { fg = c.fg3, bg = c.bg1 })
  hl('TabLine', { fg = c.fg2, bg = c.bg1 })
  hl('TabLineSel', { fg = c.bg0, bg = c.accent, bold = true })
  hl('TabLineFill', { fg = c.fg3, bg = c.bg0 })

  hl('ErrorMsg', { fg = c.err, bold = true })
  hl('WarningMsg', { fg = c.warn })
  hl('ModeMsg', { fg = c.fg1, bold = true })
  hl('MoreMsg', { fg = c.accent })
  hl('Question', { fg = c.accent })
  hl('QuickFixLine', { bg = c.bg2, bold = true })
  hl('Cursor', { fg = c.bg0, bg = c.accent2 })
  hl('lCursor', { fg = c.bg0, bg = c.accent2 })
  hl('TermCursor', { fg = c.bg0, bg = c.accent2 })

  -- Classic syntax
  hl('Comment', { fg = c.fg3, italic = true })
  hl('Constant', { fg = c.num })
  hl('String', { fg = c.str })
  hl('Character', { fg = c.str })
  hl('Number', { fg = c.num })
  hl('Boolean', { fg = c.num, bold = true })
  hl('Float', { fg = c.num })

  hl('Identifier', { fg = c.fg1 })
  hl('Function', { fg = c.fn, bold = true })

  hl('Statement', { fg = c.kw })
  hl('Conditional', { fg = c.kw })
  hl('Repeat', { fg = c.kw })
  hl('Label', { fg = c.kw })
  hl('Operator', { fg = c.fg2 })
  hl('Keyword', { fg = c.kw, bold = true })
  hl('Exception', { fg = c.err })

  hl('PreProc', { fg = c.spec })
  hl('Include', { fg = c.kw })
  hl('Define', { fg = c.spec })
  hl('Macro', { fg = c.spec })
  hl('PreCondit', { fg = c.spec })

  hl('Type', { fg = c.typ })
  hl('StorageClass', { fg = c.typ })
  hl('Structure', { fg = c.typ })
  hl('Typedef', { fg = c.typ })

  hl('Special', { fg = c.spec })
  hl('SpecialChar', { fg = c.spec })
  hl('Delimiter', { fg = c.fg2 })
  hl('Tag', { fg = c.accent })
  hl('Debug', { fg = c.warn })
  hl('Underlined', { underline = true })
  hl('Ignore', { fg = c.fg3 })
  hl('Todo', { fg = c.bg0, bg = c.warn, bold = true })
  hl('Error', { fg = c.err, bold = true })

  -- Treesitter
  link('@comment', 'Comment')
  link('@string', 'String')
  link('@string.escape', 'SpecialChar')
  link('@string.regexp', 'SpecialChar')
  link('@character', 'Character')
  link('@number', 'Number')
  link('@boolean', 'Boolean')
  link('@float', 'Float')
  link('@function', 'Function')
  link('@function.call', 'Function')
  link('@function.builtin', 'Function')
  link('@function.macro', 'Macro')
  link('@method', 'Function')
  link('@method.call', 'Function')
  link('@constructor', 'Type')
  link('@keyword', 'Keyword')
  link('@keyword.function', 'Keyword')
  link('@keyword.return', 'Keyword')
  link('@keyword.operator', 'Keyword')
  link('@keyword.import', 'Include')
  link('@conditional', 'Conditional')
  link('@repeat', 'Repeat')
  link('@label', 'Label')
  link('@exception', 'Exception')
  link('@type', 'Type')
  link('@type.builtin', 'Type')
  link('@type.definition', 'Typedef')
  link('@attribute', 'PreProc')
  link('@constant', 'Constant')
  link('@constant.builtin', 'Constant')
  link('@constant.macro', 'Macro')
  link('@namespace', 'Type')
  link('@module', 'Type')
  link('@operator', 'Operator')
  link('@punctuation.delimiter', 'Delimiter')
  link('@punctuation.bracket', 'Delimiter')
  link('@punctuation.special', 'Special')
  link('@tag', 'Tag')
  link('@tag.attribute', 'Identifier')
  link('@tag.delimiter', 'Delimiter')

  hl('@variable', { fg = c.fg1 })
  hl('@variable.builtin', { fg = c.spec, italic = true })
  hl('@variable.parameter', { fg = c.fg0 })
  hl('@variable.member', { fg = c.accent2 })
  hl('@property', { fg = c.accent2 })
  hl('@field', { fg = c.accent2 })
  hl('@text.title', { fg = c.accent, bold = true })
  hl('@text.uri', { fg = c.info, underline = true })
  hl('@text.literal', { fg = c.str })
  hl('@markup.heading', { fg = c.accent, bold = true })
  hl('@markup.link.url', { fg = c.info, underline = true })
  hl('@markup.raw', { fg = c.str })
  hl('@markup.list', { fg = c.accent })
  hl('@markup.strong', { bold = true })
  hl('@markup.italic', { italic = true })

  -- LSP semantic tokens
  link('@lsp.type.class', 'Type')
  link('@lsp.type.enum', 'Type')
  link('@lsp.type.interface', 'Type')
  link('@lsp.type.struct', 'Type')
  link('@lsp.type.parameter', '@variable.parameter')
  link('@lsp.type.property', '@property')
  link('@lsp.type.variable', '@variable')
  link('@lsp.type.function', 'Function')
  link('@lsp.type.method', 'Function')
  link('@lsp.type.macro', 'Macro')
  link('@lsp.type.namespace', 'Type')
  link('@lsp.type.decorator', 'PreProc')

  hl('LspReferenceText', { bg = c.bg3 })
  hl('LspReferenceRead', { bg = c.bg3 })
  hl('LspReferenceWrite', { bg = c.bg3, underline = true })
  hl('LspInlayHint', { fg = c.fg3, bg = c.bg1, italic = true })
  hl('LspSignatureActiveParameter', { fg = c.accent2, bold = true })
  hl('LspCodeLens', { fg = c.fg3, italic = true })

  -- Diagnostics
  hl('DiagnosticError', { fg = c.err })
  hl('DiagnosticWarn', { fg = c.warn })
  hl('DiagnosticInfo', { fg = c.info })
  hl('DiagnosticHint', { fg = c.hint })
  hl('DiagnosticOk', { fg = c.add })

  hl('DiagnosticVirtualTextError', { fg = c.err, bg = c.bg1 })
  hl('DiagnosticVirtualTextWarn', { fg = c.warn, bg = c.bg1 })
  hl('DiagnosticVirtualTextInfo', { fg = c.info, bg = c.bg1 })
  hl('DiagnosticVirtualTextHint', { fg = c.hint, bg = c.bg1 })

  hl('DiagnosticUnderlineError', { undercurl = true, sp = c.err })
  hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.warn })
  hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.info })
  hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.hint })

  -- Diffs and git
  hl('DiffAdd', { fg = c.add, bg = c.bg1 })
  hl('DiffChange', { fg = c.change, bg = c.bg1 })
  hl('DiffDelete', { fg = c.del, bg = c.bg1 })
  hl('DiffText', { fg = c.fg0, bg = c.bg3, bold = true })
  hl('Added', { fg = c.add })
  hl('Changed', { fg = c.change })
  hl('Removed', { fg = c.del })

  hl('GitSignsAdd', { fg = c.add })
  hl('GitSignsChange', { fg = c.change })
  hl('GitSignsDelete', { fg = c.del })
  hl('GitSignsCurrentLineBlame', { fg = c.fg3, italic = true })
  hl('GitSignsAddInline', { fg = c.bg0, bg = c.add })
  hl('GitSignsDeleteInline', { fg = c.bg0, bg = c.del })

  -- Telescope
  hl('TelescopeNormal', { fg = c.fg1, bg = c.bg1 })
  hl('TelescopeBorder', { fg = c.bg4, bg = c.bg1 })
  hl('TelescopeTitle', { fg = c.bg0, bg = c.accent, bold = true })
  hl('TelescopePromptNormal', { fg = c.fg0, bg = c.bg2 })
  hl('TelescopePromptBorder', { fg = c.bg2, bg = c.bg2 })
  hl('TelescopePromptTitle', { fg = c.bg0, bg = c.accent2, bold = true })
  hl('TelescopePromptPrefix', { fg = c.accent, bg = c.bg2 })
  hl('TelescopeSelection', { fg = c.fg0, bg = c.bg3, bold = true })
  hl('TelescopeSelectionCaret', { fg = c.accent2, bg = c.bg3 })
  hl('TelescopeMatching', { fg = c.accent2, bold = true })
  hl('TelescopeMultiSelection', { fg = c.accent })

  -- BufferLine
  hl('BufferLineFill', { bg = c.bg0 })
  hl('BufferLineBackground', { fg = c.fg3, bg = c.bg1 })
  hl('BufferLineBufferSelected', { fg = c.fg0, bg = c.bg0, bold = true, italic = false })
  hl('BufferLineBufferVisible', { fg = c.fg2, bg = c.bg1 })
  hl('BufferLineSeparator', { fg = c.bg0, bg = c.bg1 })
  hl('BufferLineSeparatorSelected', { fg = c.bg0, bg = c.bg0 })
  hl('BufferLineSeparatorVisible', { fg = c.bg0, bg = c.bg1 })
  hl('BufferLineIndicatorSelected', { fg = c.accent, bg = c.bg0 })
  hl('BufferLineModified', { fg = c.change, bg = c.bg1 })
  hl('BufferLineModifiedSelected', { fg = c.change, bg = c.bg0 })
  hl('BufferLineModifiedVisible', { fg = c.change, bg = c.bg1 })
  hl('BufferLineCloseButton', { fg = c.fg3, bg = c.bg1 })
  hl('BufferLineCloseButtonSelected', { fg = c.del, bg = c.bg0 })

  -- blink.cmp
  hl('BlinkCmpMenu', { fg = c.fg1, bg = c.bg1 })
  hl('BlinkCmpMenuBorder', { fg = c.bg4, bg = c.bg1 })
  hl('BlinkCmpMenuSelection', { fg = c.fg0, bg = c.bg3, bold = true })
  hl('BlinkCmpLabel', { fg = c.fg1 })
  hl('BlinkCmpLabelMatch', { fg = c.accent2, bold = true })
  hl('BlinkCmpLabelDeprecated', { fg = c.fg3, strikethrough = true })
  hl('BlinkCmpKind', { fg = c.typ })
  hl('BlinkCmpSource', { fg = c.fg3, italic = true })
  hl('BlinkCmpDoc', { fg = c.fg1, bg = c.bg1 })
  hl('BlinkCmpDocBorder', { fg = c.bg4, bg = c.bg1 })
  hl('BlinkCmpSignatureHelp', { fg = c.fg1, bg = c.bg1 })
  hl('BlinkCmpSignatureHelpActiveParameter', { fg = c.accent2, bold = true })
  hl('BlinkCmpGhostText', { fg = c.fg3, italic = true })

  -- which-key
  hl('WhichKey', { fg = c.accent2, bold = true })
  hl('WhichKeyGroup', { fg = c.accent })
  hl('WhichKeyDesc', { fg = c.fg1 })
  hl('WhichKeySeparator', { fg = c.fg3 })
  hl('WhichKeyValue', { fg = c.fg2 })
  hl('WhichKeyNormal', { bg = c.bg1 })
  hl('WhichKeyBorder', { fg = c.bg4, bg = c.bg1 })
  hl('WhichKeyTitle', { fg = c.accent, bg = c.bg1, bold = true })

  -- noice and nvim-notify
  hl('NoiceCmdlinePopup', { fg = c.fg1, bg = c.bg1 })
  hl('NoiceCmdlinePopupBorder', { fg = c.accent3, bg = c.bg1 })
  hl('NoiceCmdlineIcon', { fg = c.accent })
  hl('NoiceCmdlinePrompt', { fg = c.accent, bold = true })
  hl('NoiceConfirmBorder', { fg = c.accent3, bg = c.bg1 })
  hl('NoiceMini', { fg = c.fg2, bg = c.bg1 })
  hl('NoiceVirtualtext', { fg = c.fg3, italic = true })

  hl('NotifyBackground', { bg = c.bg1 })
  hl('NotifyERRORBorder', { fg = c.err })
  hl('NotifyWARNBorder', { fg = c.warn })
  hl('NotifyINFOBorder', { fg = c.info })
  hl('NotifyDEBUGBorder', { fg = c.fg3 })
  hl('NotifyTRACEBorder', { fg = c.accent3 })
  hl('NotifyERRORIcon', { fg = c.err })
  hl('NotifyWARNIcon', { fg = c.warn })
  hl('NotifyINFOIcon', { fg = c.info })
  hl('NotifyDEBUGIcon', { fg = c.fg3 })
  hl('NotifyTRACEIcon', { fg = c.accent3 })
  hl('NotifyERRORTitle', { fg = c.err, bold = true })
  hl('NotifyWARNTitle', { fg = c.warn, bold = true })
  hl('NotifyINFOTitle', { fg = c.info, bold = true })
  hl('NotifyDEBUGTitle', { fg = c.fg3, bold = true })
  hl('NotifyTRACETitle', { fg = c.accent3, bold = true })

  -- trouble and todo-comments
  hl('TroubleNormal', { fg = c.fg1, bg = c.bg1 })
  hl('TroubleText', { fg = c.fg1 })
  hl('TroubleCount', { fg = c.accent2, bg = c.bg2, bold = true })
  hl('TroubleIndent', { fg = c.bg4 })
  hl('TodoBgTODO', { fg = c.bg0, bg = c.info, bold = true })
  hl('TodoFgTODO', { fg = c.info })
  hl('TodoBgFIX', { fg = c.bg0, bg = c.err, bold = true })
  hl('TodoFgFIX', { fg = c.err })
  hl('TodoBgHACK', { fg = c.bg0, bg = c.warn, bold = true })
  hl('TodoFgHACK', { fg = c.warn })
  hl('TodoBgNOTE', { fg = c.bg0, bg = c.add, bold = true })
  hl('TodoFgNOTE', { fg = c.add })
  hl('TodoBgWARN', { fg = c.bg0, bg = c.warn, bold = true })
  hl('TodoFgWARN', { fg = c.warn })
  hl('TodoBgPERF', { fg = c.bg0, bg = c.accent, bold = true })
  hl('TodoFgPERF', { fg = c.accent })

  -- snacks, fidget, lazy, harpoon, toggleterm
  hl('SnacksNormal', { fg = c.fg1, bg = c.bg1 })
  hl('SnacksWinBar', { fg = c.accent, bg = c.bg2, bold = true })
  hl('SnacksBackdrop', { bg = c.bg0 })
  hl('SnacksDashboardHeader', { fg = c.accent, bold = true })
  hl('SnacksDashboardDesc', { fg = c.fg1 })
  hl('SnacksDashboardKey', { fg = c.accent2, bold = true })
  hl('SnacksDashboardIcon', { fg = c.typ })
  hl('SnacksDashboardFooter', { fg = c.fg3, italic = true })
  hl('SnacksIndent', { fg = c.bg3 })
  hl('SnacksIndentScope', { fg = c.accent3 })

  hl('FidgetTask', { fg = c.fg3 })
  hl('FidgetTitle', { fg = c.accent, bold = true })

  hl('LazyNormal', { fg = c.fg1, bg = c.bg1 })
  hl('LazyButton', { fg = c.fg2, bg = c.bg2 })
  hl('LazyButtonActive', { fg = c.bg0, bg = c.accent, bold = true })
  hl('LazyH1', { fg = c.bg0, bg = c.accent, bold = true })
  hl('LazyH2', { fg = c.accent2, bold = true })
  hl('LazyProgressDone', { fg = c.add, bold = true })
  hl('LazyProgressTodo', { fg = c.bg4 })

  hl('HarpoonWindow', { fg = c.fg1, bg = c.bg1 })
  hl('HarpoonBorder', { fg = c.accent3, bg = c.bg1 })
  hl('HarpoonTitle', { fg = c.accent, bold = true })

  hl('ToggleTerm1NormalFloat', { fg = c.fg1, bg = c.bg1 })
  hl('ToggleTerm1FloatBorder', { fg = c.accent3, bg = c.bg1 })

  -- indent-blankline
  hl('IblIndent', { fg = c.bg3 })
  hl('IblWhitespace', { fg = c.bg3 })
  hl('IblScope', { fg = c.accent3 })

  -- mini.nvim
  hl('MiniStatuslineModeNormal', { fg = c.bg0, bg = c.accent, bold = true })
  hl('MiniStatuslineModeInsert', { fg = c.bg0, bg = c.add, bold = true })
  hl('MiniStatuslineModeVisual', { fg = c.bg0, bg = c.accent2, bold = true })
  hl('MiniStatuslineModeReplace', { fg = c.bg0, bg = c.del, bold = true })
  hl('MiniStatuslineModeCommand', { fg = c.bg0, bg = c.warn, bold = true })
  hl('MiniStatuslineModeOther', { fg = c.bg0, bg = c.typ, bold = true })
  hl('MiniStatuslineDevinfo', { fg = c.fg2, bg = c.bg2 })
  hl('MiniStatuslineFilename', { fg = c.fg1, bg = c.bg1 })
  hl('MiniStatuslineFileinfo', { fg = c.fg2, bg = c.bg2 })
  hl('MiniStatuslineInactive', { fg = c.fg3, bg = c.bg1 })
  hl('MiniIconsAzure', { fg = c.info })
  hl('MiniIconsBlue', { fg = c.info })
  hl('MiniIconsCyan', { fg = c.typ })
  hl('MiniIconsGreen', { fg = c.add })
  hl('MiniIconsGrey', { fg = c.fg2 })
  hl('MiniIconsOrange', { fg = c.spec })
  hl('MiniIconsPurple', { fg = c.accent })
  hl('MiniIconsRed', { fg = c.del })
  hl('MiniIconsYellow', { fg = c.warn })

  -- Spelling
  hl('SpellBad', { undercurl = true, sp = c.err })
  hl('SpellCap', { undercurl = true, sp = c.warn })
  hl('SpellLocal', { undercurl = true, sp = c.info })
  hl('SpellRare', { undercurl = true, sp = c.hint })

  -- :terminal palette, shared verbatim with the WezTerm scheme
  local term = {
@term@
  }
  for i = 0, 15 do
    vim.g['terminal_color_' .. i] = term[i + 1]
  end
end

return M
"""


def render_starship(name: str) -> str:
    pal = prompt_palette(name)
    head = "# {} - {}\n".format(name, PALETTES[name]["desc"])
    body = STARSHIP_BODY.replace("@tq@", TQ).replace("@name@", name)
    lines = ["\n[palettes.{}]".format(name)]
    lines += ['{} = "{}"'.format(k, pal[k]) for k in PROMPT_KEY_ORDER]
    return head + body + "\n".join(lines) + "\n"


def render_nvim(name: str) -> str:
    pal = PALETTES[name]
    entries = [
        "  {} = '{}', -- {}".format(key, pal[key], comment)
        for key, comment in NVIM_KEY_ORDER
    ]
    term = "\n".join("    '{}',".format(colour) for colour in pal["term"])
    return (
        NVIM_TEMPLATE.replace("@name@", name)
        .replace("@desc@", pal["desc"])
        .replace("@palette@", "\n".join(entries))
        .replace("@term@", term)
    )


def render_wezterm(name: str) -> str:
    """The two Lua blocks dot_wezterm.lua needs, ready to paste.

    The ansi/brights ramp is the same one Neovim gives :terminal, so a shell
    inside the editor and a bare WezTerm pane render identically.
    """
    pal = PALETTES[name]
    quoted = lambda xs: ", ".join('"{}"'.format(x) for x in xs)
    scheme = """\t{n} = {{
\t\tforeground = "{fg1}",
\t\tbackground = "{bg0}",
\t\tcursor_bg = "{accent}",
\t\tcursor_fg = "{bg0}",
\t\tcursor_border = "{accent}",
\t\tselection_fg = "{fg0}",
\t\tselection_bg = "{bg3}",
\t\tansi = {{ {ansi} }},
\t\tbrights = {{ {brights} }},
\t}},""".format(n=name, ansi=quoted(pal["term"][:8]),
                brights=quoted(pal["term"][8:]), **pal)
    spec = """\t{n} = {{
\t\tcolor_scheme = "{n}",
\t\ttab_bar = {{
\t\t\tbackground = "{bg0}",
\t\t\tactive_tab = {{ bg_color = "{accent}", fg_color = "{bg0}", intensity = "Bold" }},
\t\t\tinactive_tab = {{ bg_color = "{bg1}", fg_color = "{fg3}" }},
\t\t\tinactive_tab_hover = {{ bg_color = "{bg3}", fg_color = "{fg0}", italic = true }},
\t\t\tnew_tab = {{ bg_color = "{bg0}", fg_color = "{fg3}" }},
\t\t\tnew_tab_hover = {{ bg_color = "{bg3}", fg_color = "{accent2}" }},
\t\t}},
\t}},""".format(n=name, **pal)
    return ("-- add to custom_color_schemes:\n" + scheme
            + "\n\n-- add to theme_spec:\n" + spec + "\n")


def targets() -> list:
    out = []
    for name in PALETTES:
        out.append((STARSHIP_DIR / "{}.toml".format(name), render_starship(name)))
        out.append((NVIM_DIR / "{}.lua".format(name), render_nvim(name)))
    return out


def check() -> int:
    """Assert the committed files match what this script would write."""
    stale = []
    for path, content in targets():
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current != content:
            stale.append(path.relative_to(REPO_ROOT))

    # The WezTerm ramps are pasted by hand, so verify they still agree.
    lua = WEZTERM_FILE.read_text(encoding="utf-8") if WEZTERM_FILE.exists() else ""
    for name in PALETTES:
        ansi = ", ".join('"{}"'.format(c) for c in PALETTES[name]["term"][:8])
        brights = ", ".join('"{}"'.format(c) for c in PALETTES[name]["term"][8:])
        if ansi not in lua or brights not in lua:
            stale.append("{} ({} ramp)".format(
                WEZTERM_FILE.relative_to(REPO_ROOT), name))

    if stale:
        print("Stale generated files:", file=sys.stderr)
        for item in stale:
            print("  {}".format(item), file=sys.stderr)
        print("\nRun tools/gen-themes.py to regenerate.", file=sys.stderr)
        return 1
    print("{} generated theme files are up to date.".format(len(targets())))
    return 0


def write() -> int:
    for path, content in targets():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print("wrote {}".format(path.relative_to(REPO_ROOT)))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the Starship, Neovim and WezTerm theme files.")
    parser.add_argument("--check", action="store_true",
                        help="exit non-zero if the committed files are stale")
    parser.add_argument("--wezterm", metavar="THEME",
                        help="print the Lua blocks for dot_wezterm.lua")
    args = parser.parse_args()

    if args.wezterm:
        if args.wezterm not in PALETTES:
            parser.error("unknown theme {!r}; choose from: {}".format(
                args.wezterm, ", ".join(PALETTES)))
        print(render_wezterm(args.wezterm), end="")
        return 0
    return check() if args.check else write()


if __name__ == "__main__":
    sys.exit(main())
