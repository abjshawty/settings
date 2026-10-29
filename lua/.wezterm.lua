-- Initialize wezterm and config
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Visual settings
config.font_size = 8
config.enable_tab_bar = false
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_background_opacity = 0.9
config.color_scheme = "Dark Ocean (terminal.sexy)"

-- Default Shell
config.default_prog = { "pwsh.exe", "-NoLogo" }

-- Front end
config.front_end = "WebGpu"
config.enable_kitty_keyboard = true

-- Domains: the Arch install in WSL, reachable from the launcher
config.wsl_domains = {
	{
		name = "WSL:archlinux",
		distribution = "archlinux",
		default_cwd = "~",
		default_prog = { "bash" },
	},
}

-- Keys
config.keys = {
	{
		key = "h",
		mods = "CTRL|ALT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "v",
		mods = "CTRL|ALT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.PaneSelect,
	},
}

return config
