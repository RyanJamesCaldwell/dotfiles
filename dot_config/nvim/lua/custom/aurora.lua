-- aurora - Cold night sky lit by pastel greens, pinks and ice blues.
-- Generated: keep the whole family in step rather than editing one file by hand.
local M = {}

local c = {
  bg0 = '#0f1620', -- base background
  bg1 = '#151e2b', -- panels, cursor line
  bg2 = '#1e2a3a', -- selection, popup menus
  bg3 = '#2a394d', -- borders, line numbers
  bg4 = '#3b4d66', -- dim UI
  fg0 = '#eaf2fa', -- brightest text
  fg1 = '#cbdcec', -- normal text
  fg2 = '#93a8c0', -- muted text
  fg3 = '#6b7f96', -- comments
  accent = '#a8b4f0', -- primary
  accent2 = '#f0a8d8', -- secondary
  accent3 = '#7986d0', -- deep
  str = '#8fe6c0', -- strings
  num = '#f0d9a0', -- numbers, constants
  kw = '#a8b4f0', -- keywords
  fn = '#8fd8f0', -- functions
  typ = '#f0a8d8', -- types
  spec = '#f0d9a0', -- special
  err = '#f28ba8', -- error
  warn = '#f0d9a0', -- warning
  info = '#8fd8f0', -- info
  hint = '#8fe6c0', -- hint
  add = '#8fe6c0', -- git add
  change = '#f0d9a0', -- git change
  del = '#f28ba8', -- git delete
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
  vim.g.colors_name = 'aurora'

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
    '#1e2a3a',
    '#f28ba8',
    '#8fe6c0',
    '#f0d9a0',
    '#a8b4f0',
    '#f0a8d8',
    '#8fd8f0',
    '#cbdcec',
    '#3b4d66',
    '#f5a3ba',
    '#a8f0d0',
    '#f5e4b8',
    '#bcc4f5',
    '#f5bce4',
    '#a8e4f5',
    '#eaf2fa',
  }
  for i = 0, 15 do
    vim.g['terminal_color_' .. i] = term[i + 1]
  end
end

return M
