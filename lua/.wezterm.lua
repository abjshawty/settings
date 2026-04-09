-- Initialize wezterm and config
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Visual settings
config.font_size = 8
config.enable_tab_bar = false
config.window_decorations = "TITLE | RESIZE"
config.window_background_opacity = 0.9

-- Color schemes
-- config.color_scheme = "Tokyo Night"
-- config.color_scheme = "Dark Ocean (terminal.sexy)"
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Matte Black"

-- Default Shell
config.default_prog = { "pwsh.", "-NoLogo" }
-- config.default_prog = { "powershell.exe", "-NoLogo" }
-- config.default_prog = { "wsl", "--cd", "~" }

-- Front end
config.front_end = "WebGpu"

-- Domains
config.wsl_domains = {
  {
    -- The name of this specific domain.  Must be unique amonst all types
    -- of domain in the configuration file.
    name = 'WSL:archlinux',
    
    -- The name of the distribution.  This identifies the WSL distribution.
    -- It must match a valid distribution from your `wsl -l -v` output in
    -- order for the domain to be useful.
    distribution = 'archlinux',
    
    -- The username to use when spawning commands in the distribution.
    -- If omitted, the default user for that distribution will be used.
    
    -- username = "hunter",
    
    -- The current working directory to use when spawning commands, if
    -- the SpawnCommand doesn't otherwise specify the directory.
    
    default_cwd = "~",
    
    -- The default command to run, if the SpawnCommand doesn't otherwise
    -- override it.  Note that you may prefer to use `chsh` to set the
    -- default shell for your user inside WSL to avoid needing to
    -- specify it here
    
    default_prog = {"bash"}
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
		key = "f",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SendString("ɑ"),
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
