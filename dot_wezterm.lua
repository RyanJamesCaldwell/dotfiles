-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
local theme_state_file = wezterm.home_dir .. "/.config/theme/current"
local default_theme = "nightshade"

local custom_color_schemes = {
	-- Each ramp below is copied verbatim from the matching
	-- dot_config/nvim/lua/custom/<theme>.lua, so a shell inside Neovim and a bare
	-- WezTerm pane render identical colours.
	nightshade = {
		foreground = "#d6c9e6",
		background = "#1a1324",
		cursor_bg = "#c7a9f0",
		cursor_fg = "#1a1324",
		cursor_border = "#c7a9f0",
		selection_fg = "#f2eaf8",
		selection_bg = "#3a2e51",
		ansi = { "#2d2340", "#f08a9c", "#a3dcc0", "#e9cf9e", "#a6c6ee", "#c7a9f0", "#8fd6e8", "#d6c9e6" },
		brights = { "#4b3d68", "#f4a3b2", "#b8e8cf", "#f2dcb4", "#bcd6f4", "#eba8c8", "#a8e2f0", "#f2eaf8" },
	},
	aurora = {
		foreground = "#cbdcec",
		background = "#0f1620",
		cursor_bg = "#a8b4f0",
		cursor_fg = "#0f1620",
		cursor_border = "#a8b4f0",
		selection_fg = "#eaf2fa",
		selection_bg = "#2a394d",
		ansi = { "#1e2a3a", "#f28ba8", "#8fe6c0", "#f0d9a0", "#a8b4f0", "#f0a8d8", "#8fd8f0", "#cbdcec" },
		brights = { "#3b4d66", "#f5a3ba", "#a8f0d0", "#f5e4b8", "#bcc4f5", "#f5bce4", "#a8e4f5", "#eaf2fa" },
	},
	abyss = {
		foreground = "#c5dce6",
		background = "#101c24",
		cursor_bg = "#7fd4d4",
		cursor_fg = "#101c24",
		cursor_border = "#7fd4d4",
		selection_fg = "#e8f4f8",
		selection_bg = "#2a4150",
		ansi = { "#1e313e", "#f58b8b", "#9ae0c0", "#f2cf9c", "#a9c4f0", "#e0a8d8", "#7fd4d4", "#c5dce6" },
		brights = { "#395667", "#f7a3a3", "#b0e8ce", "#f5dab4", "#bcd4f5", "#eabce4", "#9ae0e0", "#e8f4f8" },
	},
}
local theme_spec = {
	nightshade = {
		color_scheme = "nightshade",
		tab_bar = {
			background = "#1a1324",
			active_tab = { bg_color = "#c7a9f0", fg_color = "#1a1324", intensity = "Bold" },
			inactive_tab = { bg_color = "#221a2e", fg_color = "#7a6c90" },
			inactive_tab_hover = { bg_color = "#3a2e51", fg_color = "#f2eaf8", italic = true },
			new_tab = { bg_color = "#1a1324", fg_color = "#7a6c90" },
			new_tab_hover = { bg_color = "#3a2e51", fg_color = "#eba8c8" },
		},
	},
	aurora = {
		color_scheme = "aurora",
		tab_bar = {
			background = "#0f1620",
			active_tab = { bg_color = "#a8b4f0", fg_color = "#0f1620", intensity = "Bold" },
			inactive_tab = { bg_color = "#151e2b", fg_color = "#6b7f96" },
			inactive_tab_hover = { bg_color = "#2a394d", fg_color = "#eaf2fa", italic = true },
			new_tab = { bg_color = "#0f1620", fg_color = "#6b7f96" },
			new_tab_hover = { bg_color = "#2a394d", fg_color = "#f0a8d8" },
		},
	},
	abyss = {
		color_scheme = "abyss",
		tab_bar = {
			background = "#101c24",
			active_tab = { bg_color = "#7fd4d4", fg_color = "#101c24", intensity = "Bold" },
			inactive_tab = { bg_color = "#16252f", fg_color = "#667e8c" },
			inactive_tab_hover = { bg_color = "#2a4150", fg_color = "#e8f4f8", italic = true },
			new_tab = { bg_color = "#101c24", fg_color = "#667e8c" },
			new_tab_hover = { bg_color = "#2a4150", fg_color = "#f0a898" },
		},
	},
	rosepine = {
		color_scheme = "rose-pine",
		tab_bar = {
			background = "#191724",
			active_tab = { bg_color = "#eb6f92", fg_color = "#191724", intensity = "Bold" },
			inactive_tab = { bg_color = "#26233a", fg_color = "#6e6a86" },
			inactive_tab_hover = { bg_color = "#393552", fg_color = "#e0def4", italic = true },
			new_tab = { bg_color = "#191724", fg_color = "#6e6a86" },
			new_tab_hover = { bg_color = "#393552", fg_color = "#f6c177" },
		},
	},
}
local function normalize_theme_name(theme_name)
	if theme_spec[theme_name] then
		return theme_name
	end
	return default_theme
end

local function read_active_theme()
	local file = io.open(theme_state_file, "r")
	if not file then
		return default_theme
	end

	local raw = file:read("*l")
	file:close()
	if not raw then
		return default_theme
	end

	local trimmed = raw:match("^%s*(.-)%s*$")
	return normalize_theme_name(trimmed)
end

local function theme_overrides_for(theme_name)
	local normalized = normalize_theme_name(theme_name)
	local spec = theme_spec[normalized]

	return {
		color_scheme = spec.color_scheme,
		colors = {
			tab_bar = spec.tab_bar,
		},
	}
end

local initial_theme = read_active_theme()
local initial_overrides = theme_overrides_for(initial_theme)
local last_theme_by_window = {}
local is_macos = wezterm.target_triple:find("darwin") ~= nil

-- ============================================================================
-- DEV WORKSPACE LAUNCHER
-- ============================================================================

local function open_dev_workspace(window, pane)
	local cwd = pane:get_current_working_dir()
	local cwd_path = cwd and cwd.file_path or nil

	-- Compute target pixel size from current cell dimensions
	local dims = pane:get_dimensions()
	local cur_cols = dims.cols
	local cur_rows = dims.viewport_rows

	-- Resize and center window via AppleScript (uses logical screen coordinates)
	-- Ratio-based: targetSize = currentSize * (targetCells / currentCells)
	if is_macos then
		wezterm.background_child_process({
			"osascript",
			"-e", string.format([[
tell application "System Events"
	tell process "WezTerm"
		set {curW, curH} to size of front window
		set targetW to round (curW * 238 / %d)
		set targetH to round (curH * 64 / %d)
		set size of front window to {targetW, targetH}
	end tell
end tell
tell application "Finder"
	set _bounds to bounds of window of desktop
	set _sw to item 3 of _bounds
	set _sh to item 4 of _bounds
end tell
tell application "System Events"
	tell process "WezTerm"
		set {_w, _h} to size of front window
		set position of front window to {(_sw - _w) / 2, (_sh - _h) / 2}
	end tell
end tell]], cur_cols, cur_rows),
		})
	end

	-- Spawn a new tab (becomes the left pane)
	local tab, left_pane, _ = window:mux_window():spawn_tab({
		cwd = cwd_path,
	})

	-- Split: left=82 cols, right=155 cols -> right gets 155/237 ≈ 65.4%
	local right_pane = left_pane:split({
		direction = "Right",
		size = 0.654,
		cwd = cwd_path,
	})

	-- Launch copilot on the left, nvim on the right
	left_pane:send_text("copilot --yolo\n")
	right_pane:send_text("nvim\n")
end

-- This is where you actually apply your config choices
config.color_schemes = custom_color_schemes
config.color_scheme = initial_overrides.color_scheme
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 16
config.scrollback_lines = 10000
config.window_decorations = "RESIZE"
config.status_update_interval = 1000
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
	-- Dev Workspace: codex (left) + nvim (right)
	{
		key = "e",
		mods = "CMD|SHIFT",
		action = wezterm.action_callback(open_dev_workspace),
	},

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
config.hide_tab_bar_if_only_one_tab = true

-- Show pane information in tab titles
config.tab_max_width = 32

-- Tab bar styling
config.colors = initial_overrides.colors

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

wezterm.on("update-status", function(window)
	local theme = read_active_theme()
	local window_id = window:window_id()
	if last_theme_by_window[window_id] == theme then
		return
	end

	last_theme_by_window[window_id] = theme
	window:set_config_overrides(theme_overrides_for(theme))
end)

-- and finally, return the configuration to wezterm
return config
