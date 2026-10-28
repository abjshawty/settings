# Settings

This is a collection of scripts that i use in my daily life. These scripts are used to streamline my different processes so i don't have to remember everything all the time.

Do not clone this to a shared workstation, as it contains much private data.

## Structure

```
settings/
├── data/
│   └── apps.md    # All apps by category: winget, cargo, go, manual downloads
├── lua/           # Terminal and editor configs
│   ├── colorscheme.lua  # Neovim colorschemes (LazyVim)
│   └── .wezterm.lua     # WezTerm terminal config
├── omarchy/       # Omarchy hooks
│   ├── hooks/theme-set.d/  # Make Yaak and Spotify follow the Omarchy theme
│   └── install-hooks.sh    # Install every hook and apply the current theme
└── powershell/    # PowerShell profile and scripts
    ├── init.ps1   # App installer from data/apps.md
    └── profile.ps1 # Main profile (~30 functions, 30+ aliases)
```

## Installed Apps

- **Editors**: Neovim, Claude Code, Codeium Windsurf
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

To install all apps:
```
Install-AppsFromList
```

Or simply run the init script:
```
. $HOME\dev\settings\powershell\init.ps1
```

## Omarchy hooks

`omarchy/hooks/<event>.d/` mirrors `~/.config/omarchy/hooks/`. To install them all on a machine and apply the current theme right away:

```sh
./omarchy/install-hooks.sh
```

The `theme-set` hooks need some one-time setup in each app (adding the Yaak plugin, patching Spotify with Spicetify). That's documented in the vault's *Omarchy theme sync* note.

## Available Functions

Key functions in profile.ps1:
- `Connect-Wifi` / `Disconnect-Wifi` - WiFi management
- `Get-GitSSH` - Clone repos from GitHub via SSH
- `Push-Git` - Add, commit, and push in one command
- `New-NodeApp` - Scaffold new Node projects (React, Vue, Svelte, Next, etc.)
- `New-File` / `Remove-Folder` - File operations with validation
- `Set-LocationDev` - Navigate to dev workspace
- `Find-WifiKey` - Retrieve saved WiFi passwords

Key aliases:
- `v` / `vim` - nvim
- `lzg` - lazygit
- `lzd` - lazydocker
- `cd` - zoxide
- `surf` - windsurf
- `win` - winget
- `dev` - Set-LocationDev

## Terminal Setup

- **Shell**: PowerShell 7+ via WezTerm
- **Prompt**: oh-my-posh with "material" theme
- **Theme**: Matte Black (WezTerm + Neovim)
- **Icons**: eza for directory listings

