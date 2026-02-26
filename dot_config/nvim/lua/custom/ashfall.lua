-- Theme derived from your image: deep charcoal + volcanic reds + misty teal + warm cream.
-- Drop this file at: ~/.config/nvim/lua/custom/ashfall.lua
local M = {}

local c = {
	bg0 = "#0c0e14", -- deep charcoal (sky)
	bg1 = "#141a20",
	bg2 = "#252d35",
	bg3 = "#2a343d",
	bg4 = "#33383f",

	fg0 = "#fbedbd", -- warm cream (cloud highlights)
	fg1 = "#d1d3b2",
	fg2 = "#665855", -- warm gray (mountain lines)

	red0 = "#ef5137", -- hot red/orange (eruption)
	red1 = "#ed4e35",
	red2 = "#d34e37",
	red3 = "#c14736",
	red4 = "#954337",
	maroon = "#673a38",

	teal0 = "#90aea0", -- misty teal (land/water)
	teal1 = "#688581",
}

local function hl(group, spec)
	vim.api.nvim_set_hl(0, group, spec)
end

function M.setup()
	vim.opt.termguicolors = true

	-- reset
	vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") == 1 then
		vim.cmd("syntax reset")
	end
	vim.g.colors_name = "ashfall"

	-- Editor
	hl("Normal", { fg = c.fg0, bg = c.bg0 })
	hl("NormalNC", { fg = c.fg1, bg = c.bg0 })
	hl("EndOfBuffer", { fg = c.bg0, bg = c.bg0 })
	hl("SignColumn", { fg = c.fg1, bg = c.bg0 })
	hl("Folded", { fg = c.fg1, bg = c.bg1 })
	hl("FoldColumn", { fg = c.fg1, bg = c.bg0 })

	hl("LineNr", { fg = c.bg3, bg = c.bg0 })
	hl("CursorLineNr", { fg = c.fg1, bg = c.bg0, bold = true })
	hl("CursorLine", { bg = c.bg1 })
	hl("ColorColumn", { bg = c.bg1 })

	hl("WinSeparator", { fg = c.bg3, bg = c.bg0 })
	hl("VertSplit", { fg = c.bg3, bg = c.bg0 })

	hl("Visual", { bg = c.bg2 })
	hl("Search", { fg = c.bg0, bg = c.fg1 })
	hl("IncSearch", { fg = c.bg0, bg = c.red2 })
	hl("MatchParen", { fg = c.fg0, bg = c.bg2, bold = true })

	hl("Pmenu", { fg = c.fg1, bg = c.bg1 })
	hl("PmenuSel", { fg = c.bg0, bg = c.teal0, bold = true })
	hl("PmenuSbar", { bg = c.bg2 })
	hl("PmenuThumb", { bg = c.bg3 })

	hl("StatusLine", { fg = c.fg1, bg = c.bg1 })
	hl("StatusLineNC", { fg = c.bg3, bg = c.bg0 })

	hl("TabLine", { fg = c.fg1, bg = c.bg1 })
	hl("TabLineSel", { fg = c.bg0, bg = c.teal0, bold = true })
	hl("TabLineFill", { fg = c.bg3, bg = c.bg0 })

	-- Syntax (classic groups)
	hl("Comment", { fg = c.fg2, italic = true })
	hl("Constant", { fg = c.red3 })
	hl("String", { fg = c.teal0 })
	hl("Character", { fg = c.teal0 })
	hl("Number", { fg = c.red2 })
	hl("Boolean", { fg = c.red2 })
	hl("Float", { fg = c.red2 })

	hl("Identifier", { fg = c.fg0 })
	hl("Function", { fg = c.teal0, bold = true })

	hl("Statement", { fg = c.red1, bold = true })
	hl("Conditional", { fg = c.red1, bold = true })
	hl("Repeat", { fg = c.red1, bold = true })
	hl("Operator", { fg = c.fg1 })
	hl("Keyword", { fg = c.red1, bold = true })
	hl("Exception", { fg = c.red3 })

	hl("PreProc", { fg = c.red3 })
	hl("Include", { fg = c.red3 })
	hl("Define", { fg = c.red3 })
	hl("Macro", { fg = c.red3 })

	hl("Type", { fg = c.teal1, bold = true })
	hl("StorageClass", { fg = c.teal1 })
	hl("Structure", { fg = c.teal1 })
	hl("Typedef", { fg = c.teal1 })

	hl("Special", { fg = c.red2 })
	hl("SpecialChar", { fg = c.red2 })
	hl("Underlined", { underline = true })
	hl("Todo", { fg = c.bg0, bg = c.fg1, bold = true })
	hl("Error", { fg = c.fg0, bg = c.maroon, bold = true })

	-- Treesitter (links keep it simple + consistent)
	local link = function(a, b)
		hl(a, { link = b })
	end
	link("@comment", "Comment")
	link("@string", "String")
	link("@number", "Number")
	link("@boolean", "Boolean")
	link("@function", "Function")
	link("@function.call", "Function")
	link("@method", "Function")
	link("@keyword", "Keyword")
	link("@keyword.return", "Keyword")
	link("@conditional", "Conditional")
	link("@repeat", "Repeat")
	link("@type", "Type")
	link("@type.builtin", "Type")
	link("@property", "Identifier")
	link("@variable", "Identifier")
	link("@variable.builtin", "Special")
	link("@constant", "Constant")
	link("@constant.builtin", "Constant")
	link("@operator", "Operator")
	link("@punctuation.delimiter", "Operator")
	link("@punctuation.bracket", "Operator")

	-- Diagnostics (Neovim LSP)
	hl("DiagnosticError", { fg = c.red1 })
	hl("DiagnosticWarn", { fg = c.red3 })
	hl("DiagnosticInfo", { fg = c.teal0 })
	hl("DiagnosticHint", { fg = c.teal1 })

	hl("DiagnosticVirtualTextError", { fg = c.red1, bg = c.bg1 })
	hl("DiagnosticVirtualTextWarn", { fg = c.red3, bg = c.bg1 })
	hl("DiagnosticVirtualTextInfo", { fg = c.teal0, bg = c.bg1 })
	hl("DiagnosticVirtualTextHint", { fg = c.teal1, bg = c.bg1 })

	hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red1 })
	hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.red3 })
	hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.teal0 })
	hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.teal1 })

	-- Gutter git signs (works with gitsigns)
	hl("GitSignsAdd", { fg = c.teal0 })
	hl("GitSignsChange", { fg = c.red3 })
	hl("GitSignsDelete", { fg = c.red1 })

	-- Terminal colors (for :terminal and some UIs)
	vim.g.terminal_color_0 = c.bg0
	vim.g.terminal_color_1 = c.red1
	vim.g.terminal_color_2 = c.teal0
	vim.g.terminal_color_3 = c.red3
	vim.g.terminal_color_4 = c.teal1
	vim.g.terminal_color_5 = c.red4
	vim.g.terminal_color_6 = c.teal0
	vim.g.terminal_color_7 = c.fg1
	vim.g.terminal_color_8 = c.bg3
	vim.g.terminal_color_9 = c.red2
	vim.g.terminal_color_10 = c.teal0
	vim.g.terminal_color_11 = c.red3
	vim.g.terminal_color_12 = c.teal1
	vim.g.terminal_color_13 = c.red4
	vim.g.terminal_color_14 = c.teal0
	vim.g.terminal_color_15 = c.fg0
end

return M
