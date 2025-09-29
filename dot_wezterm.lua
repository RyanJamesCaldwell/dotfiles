-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.color_scheme = "rose-pine"
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 16
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 4,
	right = 0,
	top = 0,
	bottom = 0,
}

-- ============================================================================
-- PANE MANAGEMENT FOR MULTI-AGENT WORKFLOW
-- ============================================================================

config.keys = {
	-- Pane Splitting
	{
		key = "d",
		mods = "CMD",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "D",
		mods = "CMD|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},

	-- Pane Navigation (Vim-style)
	{
		key = "h",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},

	-- Pane Navigation (Arrow keys)
	{
		key = "LeftArrow",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},

	-- Pane Resizing
	{
		key = "h",
		mods = "CMD|ALT",
		action = wezterm.action.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "CMD|ALT",
		action = wezterm.action.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "k",
		mods = "CMD|ALT",
		action = wezterm.action.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "l",
		mods = "CMD|ALT",
		action = wezterm.action.AdjustPaneSize({ "Right", 5 }),
	},

	-- Close Pane
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},

	-- Zoom Pane (toggle fullscreen for current pane)
	{
		key = "z",
		mods = "CMD",
		action = wezterm.action.TogglePaneZoomState,
	},

	-- Rotate Panes
	{
		key = "r",
		mods = "CMD",
		action = wezterm.action.RotatePanes("Clockwise"),
	},
	{
		key = "R",
		mods = "CMD|SHIFT",
		action = wezterm.action.RotatePanes("CounterClockwise"),
	},

	-- Quick pane selection with numbers
	{
		key = "1",
		mods = "CMD|ALT",
		action = wezterm.action.PaneSelect({ alphabet = "1234567890" }),
	},

	-- Command Palette (search all actions)
	{
		key = "p",
		mods = "CMD|SHIFT",
		action = wezterm.action.ActivateCommandPalette,
	},
}

-- ============================================================================
-- VISUAL ENHANCEMENTS FOR PANE MANAGEMENT
-- ============================================================================

-- Show which pane is active
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.6,
}

-- Tab bar configuration
config.enable_tab_bar = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

-- Show pane information in tab titles
config.tab_max_width = 32

-- and finally, return the configuration to wezterm
return config
