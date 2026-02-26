-- Theme derived from cherry blossoms + twilight mountain/lake tones.
-- Drop this file at: ~/.config/nvim/lua/custom/sakura_night.lua
local M = {}

local c = {
  bg0 = '#0b1020', -- deep night indigo
  bg1 = '#111a2d',
  bg2 = '#1a2740',
  bg3 = '#243456',
  bg4 = '#324267',

  fg0 = '#f7e9f3', -- pale blossom cream
  fg1 = '#ddcddd',
  fg2 = '#9f92ad',

  pink0 = '#f3b0cc', -- cherry petals
  pink1 = '#e98db7',
  pink2 = '#d873a4',
  rose = '#c15b90',

  sky0 = '#a3c8ea', -- sky/lake blues
  sky1 = '#7fadd8',
  lavender = '#b7a5de',
  mist = '#6f81a8',
}

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

function M.setup()
  vim.opt.termguicolors = true

  -- reset
  vim.cmd('highlight clear')
  if vim.fn.exists('syntax_on') == 1 then
    vim.cmd('syntax reset')
  end
  vim.g.colors_name = 'sakura_night'

  -- Editor
  hl('Normal', { fg = c.fg0, bg = c.bg0 })
  hl('NormalNC', { fg = c.fg1, bg = c.bg0 })
  hl('NormalFloat', { fg = c.fg0, bg = c.bg1 })
  hl('FloatBorder', { fg = c.bg4, bg = c.bg1 })
  hl('EndOfBuffer', { fg = c.bg0, bg = c.bg0 })
  hl('SignColumn', { fg = c.fg1, bg = c.bg0 })
  hl('Folded', { fg = c.fg1, bg = c.bg1 })
  hl('FoldColumn', { fg = c.fg1, bg = c.bg0 })

  hl('LineNr', { fg = c.bg4, bg = c.bg0 })
  hl('CursorLineNr', { fg = c.pink0, bg = c.bg0, bold = true })
  hl('CursorLine', { bg = c.bg1 })
  hl('ColorColumn', { bg = c.bg1 })

  hl('WinSeparator', { fg = c.bg3, bg = c.bg0 })
  hl('VertSplit', { fg = c.bg3, bg = c.bg0 })

  hl('Visual', { bg = c.bg2 })
  hl('Search', { fg = c.bg0, bg = c.sky0 })
  hl('IncSearch', { fg = c.bg0, bg = c.pink1, bold = true })
  hl('MatchParen', { fg = c.fg0, bg = c.bg2, bold = true })

  hl('Pmenu', { fg = c.fg1, bg = c.bg1 })
  hl('PmenuSel', { fg = c.bg0, bg = c.pink0, bold = true })
  hl('PmenuSbar', { bg = c.bg2 })
  hl('PmenuThumb', { bg = c.bg3 })

  hl('StatusLine', { fg = c.fg1, bg = c.bg1 })
  hl('StatusLineNC', { fg = c.bg4, bg = c.bg0 })

  hl('TabLine', { fg = c.fg1, bg = c.bg1 })
  hl('TabLineSel', { fg = c.bg0, bg = c.pink0, bold = true })
  hl('TabLineFill', { fg = c.bg4, bg = c.bg0 })

  -- Syntax (classic groups)
  hl('Comment', { fg = c.mist, italic = true })
  hl('Constant', { fg = c.lavender })
  hl('String', { fg = c.sky0 })
  hl('Character', { fg = c.sky0 })
  hl('Number', { fg = c.pink1 })
  hl('Boolean', { fg = c.pink1 })
  hl('Float', { fg = c.pink1 })

  hl('Identifier', { fg = c.fg0 })
  hl('Function', { fg = c.pink0, bold = true })

  hl('Statement', { fg = c.rose, bold = true })
  hl('Conditional', { fg = c.rose, bold = true })
  hl('Repeat', { fg = c.rose, bold = true })
  hl('Operator', { fg = c.fg1 })
  hl('Keyword', { fg = c.rose, bold = true })
  hl('Exception', { fg = c.pink2 })

  hl('PreProc', { fg = c.pink2 })
  hl('Include', { fg = c.pink2 })
  hl('Define', { fg = c.pink2 })
  hl('Macro', { fg = c.pink2 })

  hl('Type', { fg = c.sky1, bold = true })
  hl('StorageClass', { fg = c.sky1 })
  hl('Structure', { fg = c.sky1 })
  hl('Typedef', { fg = c.sky1 })

  hl('Special', { fg = c.lavender })
  hl('SpecialChar', { fg = c.lavender })
  hl('Underlined', { underline = true })
  hl('Todo', { fg = c.bg0, bg = c.pink0, bold = true })
  hl('Error', { fg = c.fg0, bg = c.rose, bold = true })

  -- Treesitter
  local link = function(a, b)
    hl(a, { link = b })
  end
  link('@comment', 'Comment')
  link('@string', 'String')
  link('@number', 'Number')
  link('@boolean', 'Boolean')
  link('@function', 'Function')
  link('@function.call', 'Function')
  link('@method', 'Function')
  link('@keyword', 'Keyword')
  link('@keyword.return', 'Keyword')
  link('@conditional', 'Conditional')
  link('@repeat', 'Repeat')
  link('@type', 'Type')
  link('@type.builtin', 'Type')
  link('@property', 'Identifier')
  link('@variable', 'Identifier')
  link('@variable.builtin', 'Special')
  link('@constant', 'Constant')
  link('@constant.builtin', 'Constant')
  link('@operator', 'Operator')
  link('@punctuation.delimiter', 'Operator')
  link('@punctuation.bracket', 'Operator')

  -- Diagnostics
  hl('DiagnosticError', { fg = c.pink2 })
  hl('DiagnosticWarn', { fg = c.pink1 })
  hl('DiagnosticInfo', { fg = c.sky0 })
  hl('DiagnosticHint', { fg = c.sky1 })

  hl('DiagnosticVirtualTextError', { fg = c.pink2, bg = c.bg1 })
  hl('DiagnosticVirtualTextWarn', { fg = c.pink1, bg = c.bg1 })
  hl('DiagnosticVirtualTextInfo', { fg = c.sky0, bg = c.bg1 })
  hl('DiagnosticVirtualTextHint', { fg = c.sky1, bg = c.bg1 })

  hl('DiagnosticUnderlineError', { undercurl = true, sp = c.pink2 })
  hl('DiagnosticUnderlineWarn', { undercurl = true, sp = c.pink1 })
  hl('DiagnosticUnderlineInfo', { undercurl = true, sp = c.sky0 })
  hl('DiagnosticUnderlineHint', { undercurl = true, sp = c.sky1 })

  -- Gutter git signs
  hl('GitSignsAdd', { fg = c.sky0 })
  hl('GitSignsChange', { fg = c.lavender })
  hl('GitSignsDelete', { fg = c.pink2 })

  -- Terminal colors
  vim.g.terminal_color_0 = c.bg0
  vim.g.terminal_color_1 = c.pink2
  vim.g.terminal_color_2 = c.sky0
  vim.g.terminal_color_3 = c.pink1
  vim.g.terminal_color_4 = c.sky1
  vim.g.terminal_color_5 = c.lavender
  vim.g.terminal_color_6 = c.sky0
  vim.g.terminal_color_7 = c.fg1
  vim.g.terminal_color_8 = c.bg4
  vim.g.terminal_color_9 = c.rose
  vim.g.terminal_color_10 = c.sky0
  vim.g.terminal_color_11 = c.pink1
  vim.g.terminal_color_12 = c.sky1
  vim.g.terminal_color_13 = c.lavender
  vim.g.terminal_color_14 = c.sky0
  vim.g.terminal_color_15 = c.fg0
end

return M
