local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font_size = 10
config.enable_tab_bar = false
config.window_decorations = "RESIZE" -- "TITLE | RESIZE"
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 0.5
config.default_prog = { 'powershell.exe', '-NoLogo' }
config.front_end = 'WebGpu'
config.keys = {
	{
		key = 'h',
		mods = 'CTRL|ALT',
		action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
	},
	{
		key = 'v',
		mods = 'CTRL|ALT',
		action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
	},
	{
		key = 'f',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.SendString("ɑ"),
	},
	{
		key = 'w',
		mods = 'CTRL',
		action = wezterm.action.CloseCurrentPane { confirm = true },
	},
	{
		key = 'Tab',
		mods = 'CTRL',
		action = wezterm.action.PaneSelect,
	}
}

return config
