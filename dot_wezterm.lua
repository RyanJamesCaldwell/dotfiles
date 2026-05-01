-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
local theme_state_file = wezterm.home_dir .. "/.config/theme/current"
local default_theme = "sakura_night"

local custom_color_schemes = {
	sakura_night = {
		foreground = "#f7e9f3",
		background = "#0b1020",
		cursor_bg = "#f3b0cc",
		cursor_fg = "#0b1020",
		cursor_border = "#f3b0cc",
		selection_fg = "#f7e9f3",
		selection_bg = "#1a2740",
		ansi = { "#0b1020", "#d873a4", "#a3c8ea", "#e98db7", "#7fadd8", "#b7a5de", "#a3c8ea", "#ddcddd" },
		brights = { "#324267", "#c15b90", "#a3c8ea", "#e98db7", "#7fadd8", "#b7a5de", "#a3c8ea", "#f7e9f3" },
	},
	ashfall = {
		foreground = "#fbedbd",
		background = "#0c0e14",
		cursor_bg = "#d34e37",
		cursor_fg = "#0c0e14",
		cursor_border = "#d34e37",
		selection_fg = "#fbedbd",
		selection_bg = "#252d35",
		ansi = { "#0c0e14", "#ed4e35", "#90aea0", "#c14736", "#688581", "#954337", "#90aea0", "#d1d3b2" },
		brights = { "#2a343d", "#d34e37", "#90aea0", "#c14736", "#688581", "#954337", "#90aea0", "#fbedbd" },
	},
}

local theme_spec = {
	sakura_night = {
		color_scheme = "sakura_night",
		tab_bar = {
			background = "#0b1020",
			active_tab = { bg_color = "#e98db7", fg_color = "#0b1020", intensity = "Bold" },
			inactive_tab = { bg_color = "#111a2d", fg_color = "#6f81a8" },
			inactive_tab_hover = { bg_color = "#243456", fg_color = "#f7e9f3", italic = true },
			new_tab = { bg_color = "#0b1020", fg_color = "#6f81a8" },
			new_tab_hover = { bg_color = "#243456", fg_color = "#a3c8ea" },
		},
	},
	ashfall = {
		color_scheme = "ashfall",
		tab_bar = {
			background = "#0c0e14",
			active_tab = { bg_color = "#90aea0", fg_color = "#0c0e14", intensity = "Bold" },
			inactive_tab = { bg_color = "#141a20", fg_color = "#665855" },
			inactive_tab_hover = { bg_color = "#252d35", fg_color = "#fbedbd", italic = true },
			new_tab = { bg_color = "#0c0e14", fg_color = "#665855" },
			new_tab_hover = { bg_color = "#252d35", fg_color = "#ed4e35" },
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
