-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.color_scheme = "rose-pine"
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 16
config.scrollback_lines = 10000
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

	-- Quick Select (URLs/paths)
	{
		key = "f",
		mods = "CMD|SHIFT",
		action = wezterm.action.QuickSelect,
	},

	-- Scrollback Search
	{
		key = "f",
		mods = "CMD",
		action = wezterm.action.Search({ CaseSensitiveString = "" }),
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
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

-- Show pane information in tab titles
config.tab_max_width = 32

-- Tab bar styling
config.colors = {
	tab_bar = {
		background = "#191724",
		active_tab = {
			bg_color = "#eb6f92",
			fg_color = "#191724",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#26233a",
			fg_color = "#6e6a86",
		},
		inactive_tab_hover = {
			bg_color = "#393552",
			fg_color = "#e0def4",
			italic = true,
		},
		new_tab = {
			bg_color = "#191724",
			fg_color = "#6e6a86",
		},
		new_tab_hover = {
			bg_color = "#393552",
			fg_color = "#f6c177",
		},
	},
}

-- Smart tab naming based on current directory
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local pane = tab.active_pane
	local title = pane.title

	-- Use directory name if in a git repo
	if pane.current_working_dir then
		title = pane.current_working_dir.file_path:match("([^/]+)/?$") or title
	end

	local is_active = tab.is_active
	local separator = is_active and "█" or "▌"

	return {
		{ Text = separator .. " " .. tab.tab_index + 1 .. ": " .. title .. " " },
	}
end)

-- and finally, return the configuration to wezterm
return config
