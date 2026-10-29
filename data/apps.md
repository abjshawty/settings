# Apps

Everything installed on this machine, grouped by category. Each section ends with a copy-paste block.

Install order matters: **Languages & Toolchains** first (Rust and Go are needed for the Cargo and Go sections), then everything else.

> `powershell/init.ps1` reads every `winget install` line in this file, so keep one install per line.

---

## Languages & Toolchains

| App | ID | Description |
| --- | --- | --- |
| Go | `Golang.Go` | Go compiler and toolchain (needed for the Go tools below) |
| Rustup | `Rustlang.Rustup` | Rust toolchain installer: `rustc`, `cargo` (needed for the Cargo tools below) |
| Python 3.14 | `Python.Python.3.14` | Python interpreter and `pip` |
| NVM for Windows | `CoreyButler.NVMforWindows` | Node.js version manager |
| Azul Zulu JDK 21 | `Azul.Zulu.21.JDK` | OpenJDK 21 build (needed by the Android command-line tools) |
| WinLibs (GCC) | `BrechtSanders.WinLibs.POSIX.UCRT` | GCC / MinGW-w64 toolchain (POSIX threads, UCRT) |
| LLVM | `LLVM.LLVM` | Clang, LLD and the rest of the LLVM toolchain |
| VS 2022 Build Tools | `Microsoft.VisualStudio.2022.BuildTools` | MSVC compiler and Windows SDK (C++ workload), required by Rust's MSVC target |

```powershell
winget install --id Golang.Go -e
winget install --id Rustlang.Rustup -e
winget install --id Python.Python.3.14 -e
winget install --id CoreyButler.NVMforWindows -e
winget install --id Azul.Zulu.21.JDK -e
winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e
winget install --id LLVM.LLVM -e
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

## AI & Agents

| App | ID | Description |
| --- | --- | --- |
| Claude Code | `Anthropic.ClaudeCode` | Anthropic's agentic coding CLI |
| Claude | `Anthropic.Claude` | Claude desktop app |
| opencode | `SST.opencode` | Open-source AI coding agent for the terminal |
| LM Studio | `ElementLabs.LMStudio` | Download and run local LLMs |
| Handy | `cjpais.Handy` | Offline push-to-talk speech-to-text |

```powershell
winget install --id Anthropic.ClaudeCode -e
winget install --id Anthropic.Claude -e
winget install --id SST.opencode -e
winget install --id ElementLabs.LMStudio -e
winget install --id cjpais.Handy -e
```

## Editors

| App | ID | Description |
| --- | --- | --- |
| Neovim | `Neovim.Neovim` | Modal text editor (LazyVim config) |
| Zed | `ZedIndustries.Zed` | Fast native editor written in Rust |

```powershell
winget install --id Neovim.Neovim -e
winget install --id ZedIndustries.Zed -e
```

## Terminals & Shell

| App | ID | Description |
| --- | --- | --- |
| PowerShell | `Microsoft.PowerShell` | PowerShell 7+, the main shell |
| Windows Terminal | `Microsoft.WindowsTerminal` | Microsoft's tabbed terminal |
| WSL | `Microsoft.WSL` | Windows Subsystem for Linux |
| WezTerm | `wez.wezterm` | GPU-accelerated terminal, configured in Lua |
| Warp | `Warp.Warp` | Modern terminal with built-in AI and blocks |
| Oh My Posh | `JanDeDobbeleer.OhMyPosh` | Prompt theme engine |
| Termius | `Termius.Termius` | SSH client with synced hosts and keys |

```powershell
winget install --id Microsoft.PowerShell -e
winget install --id Microsoft.WindowsTerminal -e
winget install --id Microsoft.WSL -e
winget install --id wez.wezterm -e
winget install --id Warp.Warp -e
winget install --id JanDeDobbeleer.OhMyPosh -e
winget install --id Termius.Termius -e
```

## CLI Utilities

| App | ID | Description |
| --- | --- | --- |
| bat | `sharkdp.bat` | `cat` with syntax highlighting and Git integration |
| eza | `eza-community.eza` | Modern `ls` with icons and Git status |
| fzf | `junegunn.fzf` | Fuzzy finder for files, history, anything |
| ripgrep | `BurntSushi.ripgrep.MSVC` | Very fast recursive search (`rg`) |
| fd | `sharkdp.fd` | Fast, friendly alternative to `find` |
| jq | `jqlang.jq` | Query and transform JSON |
| zoxide | `ajeetdsouza.zoxide` | Smarter `cd` that learns your folders |
| tealdeer | `dbrgn.tealdeer` | Fast `tldr` client: short command examples |
| Glow | `charmbracelet.glow` | Render Markdown in the terminal |
| Fastfetch | `Fastfetch-cli.Fastfetch` | System info display |
| btop4win | `aristocratos.btop4win` | Resource monitor (CPU, memory, disks, network) |
| cURL | `cURL.cURL` | HTTP and transfer tool |
| 7-Zip | `7zip.7zip` | Archive manager (zip, 7z, tar, rar…) |
| cloudflared | `Cloudflare.cloudflared` | Cloudflare Tunnel client: expose local servers |

```powershell
winget install --id sharkdp.bat -e
winget install --id eza-community.eza -e
winget install --id junegunn.fzf -e
winget install --id BurntSushi.ripgrep.MSVC -e
winget install --id sharkdp.fd -e
winget install --id jqlang.jq -e
winget install --id ajeetdsouza.zoxide -e
winget install --id dbrgn.tealdeer -e
winget install --id charmbracelet.glow -e
winget install --id Fastfetch-cli.Fastfetch -e
winget install --id aristocratos.btop4win -e
winget install --id cURL.cURL -e
winget install --id 7zip.7zip -e
winget install --id Cloudflare.cloudflared -e
```

## Git & Containers

| App | ID | Description |
| --- | --- | --- |
| Git | `Git.Git` | Version control (includes Git Bash) |
| GitHub CLI | `GitHub.cli` | `gh`: PRs, issues and repos from the terminal |
| lazygit | `JesseDuffield.lazygit` | Terminal UI for Git |
| Docker Desktop | `Docker.DockerDesktop` | Containers and Docker Compose |
| lazydocker | `JesseDuffield.lazydocker` | Terminal UI for Docker |

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id JesseDuffield.lazygit -e
winget install --id Docker.DockerDesktop -e
winget install --id JesseDuffield.lazydocker -e
```

## Databases & APIs

| App | ID | Description |
| --- | --- | --- |
| PostgreSQL 18 | `PostgreSQL.PostgreSQL.18` | PostgreSQL server, `psql` and pgAdmin |
| DBX | `t8y2.DBX` | Lightweight cross-platform database client |
| Bruno | `Bruno.Bruno` | Offline, Git-friendly API client |

```powershell
winget install --id PostgreSQL.PostgreSQL.18 -e
winget install --id t8y2.DBX -e
winget install --id Bruno.Bruno -e
```

## Browsers

| App | ID | Description |
| --- | --- | --- |
| Firefox Developer Edition | `Mozilla.Firefox.DeveloperEdition` | Firefox with extra dev tools |
| Zen Browser | `Zen-Team.Zen-Browser` | Firefox-based browser with vertical tabs |

```powershell
winget install --id Mozilla.Firefox.DeveloperEdition -e
winget install --id Zen-Team.Zen-Browser -e
```

## Productivity & Communication

| App | ID | Description |
| --- | --- | --- |
| Notion | `Notion.Notion` | Notes, docs and wikis |
| Obsidian | `Obsidian.Obsidian` | Local Markdown notes and knowledge base |
| LocalSend | `LocalSend.LocalSend` | AirDrop-style file sharing over the local network |
| Thunderbird | `Mozilla.Thunderbird` | Email client |
| Discord | `Discord.Discord` | Voice and text chat |

```powershell
winget install --id Notion.Notion -e
winget install --id Obsidian.Obsidian -e
winget install --id LocalSend.LocalSend -e
winget install --id Mozilla.Thunderbird -e
winget install --id Discord.Discord -e
```

## Media & Gaming

| App | ID | Description |
| --- | --- | --- |
| Spotify | `Spotify.Spotify` | Music streaming |
| REAPER | `Cockos.REAPER` | Digital audio workstation |
| Steam | `Valve.Steam` | Game store and launcher |
| Epic Games Launcher | `EpicGames.EpicGamesLauncher` | Game store and launcher |

```powershell
winget install --id Spotify.Spotify -e
winget install --id Cockos.REAPER -e
winget install --id Valve.Steam -e
winget install --id EpicGames.EpicGamesLauncher -e
```

---

## Cargo Tools

Requires **Rustup** (and the VS Build Tools for the MSVC linker).

| Tool | Description |
| --- | --- |
| tree-sitter-cli | Tree-sitter parser generator, used by Neovim to build grammars |

```powershell
cargo install tree-sitter-cli
```

## Go Tools

Requires **Go**.

| Tool | Description |
| --- | --- |
| lazysql | Terminal UI SQL client (MySQL, Postgres, SQLite, MSSQL) |
| lazycurl | Terminal UI HTTP client |

```powershell
go install github.com/jorgerojas26/lazysql@latest
go install github.com/kbrdn1/LazyCurl/cmd/lazycurl@latest
```

## Manual Downloads

| Tool | Description |
| --- | --- |
| [Android command-line tools (Linux)](https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip) | `sdkmanager`, `avdmanager` and friends, without Android Studio |
