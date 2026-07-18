-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	{
		"dlyongemallo/diffview-plus.nvim",
		version = "*",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewFileHistory",
		},
		keys = {
			{
				"<leader>gf",
				"<cmd>DiffviewOpen HEAD<cr>",
				desc = "Review git changes since HEAD",
			},
			{
				"<leader>gq",
				"<cmd>DiffviewClose<cr>",
				desc = "Close git review",
			},
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				default = {
					layout = "diff2_horizontal",
				},
			},
			file_panel = {
				listing_style = "tree",
				win_config = {
					position = "left",
					width = 35,
				},
			},
			hooks = {
				diff_buf_read = function(bufnr)
					vim.api.nvim_buf_call(bufnr, function()
						vim.opt_local.wrap = false
						vim.opt_local.list = false
					end)
				end,
			},
		},
	},
}
