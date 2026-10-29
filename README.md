# Settings

This is a collection of scripts that i use in my daily life. These scripts are used to streamline my different processes so i don't have to remember everything all the time.

Do not clone this to a shared workstation, as it contains much private data.

## Structure

```
settings/
├── data/
│   └── apps.md          # Windows apps by category: winget, cargo, go, manual downloads
├── linux/               # Arch / Omarchy setup (see linux/README.md)
├── lua/
│   ├── colorscheme.lua  # Neovim colorschemes (LazyVim)
│   └── .wezterm.lua     # WezTerm terminal config (Windows)
├── powershell/
│   ├── init.ps1         # Installs every app in data/apps.md, then loads the profile
│   └── profile.ps1      # Main profile: functions and aliases
└── rust/
    └── search/          # `search` CLI: open a search-engine query in the browser
```

## Installed Apps

- **Editors**: Neovim, Zed, Claude Code
- **Languages**: Go, Rust, Python 3.14, Node.js (via NVM)
- **Dev Tools**: lazygit, lazydocker, lazysql, lazycurl, fzf, bat, eza, glow, tealdeer
- **Terminal**: WezTerm, oh-my-posh, zoxide, eza
- **Databases**: DBX
- **Misc**: Docker Desktop, Spotify, Discord, Thunderbird, REAPER, Zen Browser

## Using it

Find your `$Profile` file via PowerShell, then paste:

```
. $HOME\dev\settings\powershell\profile.ps1
```

Every new powershell instance will now load the scripts on launch.

To install all apps from `data/apps.md` and load the profile, run the init script:
```
. $HOME\dev\settings\powershell\init.ps1
```

To build the `search` tool used by the profile's `search` function:
```
cd $HOME\dev\settings\rust\search
cargo build --release
```

## Available Functions

Key functions in profile.ps1:
- `Connect-Wifi` / `Disconnect-Wifi` - WiFi management
- `Get-GitSSH` - Clone repos from GitHub via SSH
- `Push-Git` - Add, commit, and push in one command
- `Open-Origin` - Open the current repo's remote in the browser
- `New-NodeApp` - Scaffold new Node projects (React, Vue, Svelte, Next, etc.)
- `New-File` / `Remove-Folder` - Create (or touch) files, delete folders with a confirmation
- `Set-LocationDev` - Navigate to dev workspace
- `Find-WifiKey` - Retrieve saved WiFi passwords
- `search` - Search the web from the terminal (`search --help`)

Key aliases:
- `n` - nvim (opens the current folder with no arguments)
- `lzg` / `lzd` / `lzs` / `lzc` - lazygit / lazydocker / lazysql / lazycurl
- `cd` - zoxide
- `win` - `winget update --all`, or `winget install` with arguments
- `dev` - Set-LocationDev
- `hist` - Search command history
- `b` - Open a URL in the default browser

## Terminal Setup

- **Shell**: PowerShell 7+ via WezTerm
- **Prompt**: oh-my-posh with "material" theme
- **Theme**: Dark Ocean (WezTerm), Matte Black (Neovim)
- **Icons**: eza for directory listings
