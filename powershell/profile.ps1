# ============================================================================
# VARIABLES
# ============================================================================

$workspace = ((Get-Item (split-path -parent  $MyInvocation.MyCommand.Definition)).parent.parent).FullName
if (-not $workspace) {
    $workspace = "$HOME\dev"
}
# ============================================================================
# INITIALIZATION
# ============================================================================

oh-my-posh init pwsh --config "material" | Invoke-Expression 2>$null
zoxide.exe init powershell | Out-String | Invoke-Expression 2>$null

# ============================================================================
# CLEANUP
# ============================================================================

if (Test-Path alias:rmdir) { Remove-Item alias:rmdir }
if (Test-Path alias:ls) { Remove-Item alias:ls }
if (Test-Path alias:cd) { Remove-Item alias:cd }
if (Test-Path alias:curl) {Remove-Item alias:curl}
# `search` is now a function (the Rust CLI); drop any stale alias so it wins on re-source
if (Test-Path alias:search) { Remove-Item alias:search }
# ============================================================================
# FUNCTIONS (Alphabetical Order)
# ============================================================================

function Connect-Wifi {
    <#
    .SYNOPSIS
        Connects to a saved WiFi network.
    .PARAMETER Name
        The name of the saved WiFi profile to connect to.
    .EXAMPLE
        Connect-Wifi "MyNetwork"
        Connects to the WiFi network named "MyNetwork"
    #>
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )
    netsh.exe wlan connect $Name
}

function Disconnect-Wifi {
    <#
    .SYNOPSIS
        Disconnects from the current WiFi network.
    #>
    netsh.exe wlan disconnect
}

function unzip {
    <#
    .SYNOPSIS
        Extracts the contents of a zip file to a specified directory.
    .DESCRIPTION
        Uses Expand-Archive to extract zip files.
    .PARAMETER file
        The path to the zip file to extract.
    .PARAMETER destination
        The directory where files should be extracted (default: current directory).
    .EXAMPLE
        unzip "C:\path\to\your\file.zip"
        Extracts file.zip to current directory
    .EXAMPLE
        unzip "C:\path\to\your\file.zip" "C:\extracted\folder"
        Extracts to specified directory
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $file,
        [Parameter(Position = 1)]
        [string]
        $destination = "."
    )
    Expand-Archive -Path $file -DestinationPath $destination -Force
}

function Find-FromPort {
    <#
    .SYNOPSIS
        Finds processes using a specific port.
    .DESCRIPTION
        Uses netstat to find which processes are listening on or using a specific port.
        Returns the process ID and connection information.
    .PARAMETER port
        The port number to search for.
    .EXAMPLE
        Find-FromPort "8080"
        Shows all processes using port 8080
    #>
    param(
        [Parameter()]
        [string]
        $port
    )
    netstat -ano | Select-String ":$port"
}

function Find-HTTPSUrl {
    <#
    .SYNOPSIS
        Converts Git SSH URLs to HTTPS URLs.
    .DESCRIPTION
        Transforms Git SSH URLs (git@github.com:user/repo.git or
        ssh://git@github.com/user/repo.git) to HTTPS URLs. HTTPS URLs are
        returned unchanged.
    .PARAMETER url
        The Git URL to convert (SSH or HTTPS format).
    .EXAMPLE
        Find-HTTPSUrl -url "git@github.com:user/repo.git"
        Returns "https://github.com/user/repo.git"
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $url
    )
    $url -replace '^(?:ssh://)?git@([^:/]+)[:/]', 'https://$1/'
}

function Find-Port {
    <#
    .SYNOPSIS
        Gets the local port used by a specific process.
    .DESCRIPTION
        Retrieves the local port number that a process is listening on.
        Useful for identifying which port your application is using.
    .PARAMETER processId
        The ID of the process to find the port for.
    .EXAMPLE
        Find-Port -processId "1234"
        Returns the port number used by process ID 1234
    #>
    param(
        [Parameter(Mandatory)]
        [string]
        $processId
    )
    (Get-NetTcpConnection -OwningProcess $processId | Select-Object LocalPort).LocalPort
}

function Find-WifiKey {
    <#
    .SYNOPSIS
        Retrieves the WiFi password for a specified network.
    .DESCRIPTION
        Uses netsh to show the WiFi profile and extracts the password.
        Requires administrative privileges to view network keys.
    .PARAMETER name
        The name of the WiFi network to get the password for.
    .EXAMPLE
        Find-WifiKey "MyNetwork"
        Shows the password for WiFi network "MyNetwork"
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $name
    )
    netsh.exe wlan show profile $name key=clear | Select-String "Key"
}

function Get-DefaultBrowserName {
    <#
    .SYNOPSIS
        Gets the name of the default system browser.
    .DESCRIPTION
        Reads Windows registry to determine which browser is set as default.
        Returns human-readable browser names like "Google Chrome" or "Mozilla Firefox".
    .EXAMPLE
        Get-DefaultBrowserName
        Returns "Google Chrome" if Chrome is the default browser
    #>
    $browserRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
    $browserProgId = (Get-ItemProperty $browserRegPath).ProgId

    switch -Regex ($browserProgId) {
        "^Chrome" { return "Google Chrome" }
        "^Firefox" { return "Firefox/Zen" }
        "^MSEdge" { return "Microsoft Edge" }
        "^IE" { return "Microsoft Edge (or Internet Explorer)" }
        "Helium" { return "Helium" }
        default { return "Unknown or non-standard browser (ProgId: $browserProgId)" }
    }
}

function Get-DefaultBrowserPath {
    <#
    .SYNOPSIS
        Gets the executable path of the default system browser.
    .DESCRIPTION
        Reads Windows registry to determine the full path to the default browser executable.
        Useful for launching URLs programmatically.
    .EXAMPLE
        Get-DefaultBrowserPath
        Returns "C:\Program Files\Google\Chrome\Application\chrome.exe" if Chrome is default
    #>
    $browserRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
    $browserProgId = (Get-ItemProperty $browserRegPath).ProgId
    $regPath = "Registry::HKEY_CLASSES_ROOT\$browserProgId\shell\open\command"
    $browserObj = Get-ItemProperty $regPath
    # Extract just the executable path from the command string
    $browserObj.'(default)' -replace '^"([^"]+)".*$', '$1'
}

function Get-GitSSH {
    <#
    .SYNOPSIS
        Clones a repository from GitHub using SSH.
    .DESCRIPTION
        Creates a git clone command for the specified repository from the abjshawty GitHub account.
        Uses SSH protocol for cloning.
    .PARAMETER Project
        The name of the repository to clone (without .git extension).
    .PARAMETER Username
        GitHub username (default: abjshawty).
    .PARAMETER Destination
        Destination directory (default: current directory).
    .PARAMETER Branch
        Specific branch to clone (default: default branch).
    .EXAMPLE
        Get-GitSSH "my-repo"
        Clones git@github.com:abjshawty/my-repo.git
    .EXAMPLE
        Get-GitSSH "my-repo" -Username "otheruser" -Destination "C:\Projects"
        Clones from different user to specific directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [ValidateLength(1, 100)]
        [string]
        $Project,
        
        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [ValidateLength(1, 39)]
        [string]
        $Username = "abjshawty",
        
        [Parameter()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "Destination directory '$_' does not exist"
                }
                $true
            })]
        [string]
        $Destination = ".",
        
        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9._/-]+$')]
        [string]
        $Branch = ""
    )
    
    try {
        Write-Verbose "Attempting to clone repository: $Project"
        
        # Check if git is available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Git is not installed or not in PATH"
            Write-Warning "Install Git from https://git-scm.com/"
            return
        }
        
        # Validate username format
        if ($Username -notmatch '^[a-zA-Z0-9._-]+$') {
            Write-Error "Invalid GitHub username format: $Username"
            return
        }
        
        # Build repository URL
        $repoUrl = "git@github.com:${Username}/${Project}.git"
        Write-Verbose "Repository URL: $repoUrl"
        
        # Check if SSH key is configured
        Write-Verbose "Testing SSH connection to GitHub..."
        $sshTest = git ls-remote $repoUrl 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($sshTest -match "Permission denied" -or $sshTest -match "authentication failed") {
                Write-Error "SSH key authentication failed"
                Write-Warning "Make sure your SSH key is configured with GitHub"
                Write-Warning "Run 'ssh-keygen -t ed25519 -C \"your_email@example.com\"' to generate a key"
                Write-Warning "Then add the public key to your GitHub account"
                return
            }
            elseif ($sshTest -match "not found") {
                Write-Error "Repository '${Username}/${Project}' does not exist or is not accessible"
                return
            }
            else {
                Write-Error "SSH connection failed: $sshTest"
                return
            }
        }
        
        # Determine destination path
        $destPath = Join-Path $Destination $Project
        Write-Verbose "Destination path: $destPath"
        
        # Check if repository already exists locally
        if (Test-Path $destPath) {
            Write-Warning "Directory '$destPath' already exists"
            
            # Check if it's a git repository
            if (Test-Path (Join-Path $destPath ".git")) {
                Write-Warning "Directory is already a git repository"
                $choice = Read-Host "Do you want to remove it and clone fresh? (y/N)"
                if ($choice -match '^[Yy]') {
                    Remove-Item -Path $destPath -Recurse -Force
                }
                else {
                    Write-Output "Clone cancelled"
                    return
                }
            }
            else {
                Write-Warning "Directory exists but is not a git repository"
                $choice = Read-Host "Do you want to remove it and clone? (y/N)"
                if ($choice -match '^[Yy]') {
                    Remove-Item -Path $destPath -Recurse -Force
                }
                else {
                    Write-Output "Clone cancelled"
                    return
                }
            }
        }
        
        # Build clone command
        $cloneArgs = @("clone", $repoUrl)
        
        if ($Branch) {
            $cloneArgs += "--branch", $Branch
            Write-Verbose "Cloning branch: $Branch"
        }
        
        $cloneArgs += $destPath
        
        Write-Verbose "Git command: git $($cloneArgs -join ' ')"
        
        # Execute clone
        $result = git @cloneArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully cloned repository: $Project"
            Write-Output "Repository location: $(Resolve-Path $destPath)"
            
            # Show repository info
            if (Test-Path $destPath) {
                Push-Location $destPath
                try {
                    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
                    $commitCount = git rev-list --count HEAD 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Output "Branch: $currentBranch, Commits: $commitCount"
                    }
                }
                finally {
                    Pop-Location
                }
            }
        }
        else {
            Write-Error "Failed to clone repository '$Project'"
            Write-Warning "Git output: $result"
            
            if ($result -match "Repository not found") {
                Write-Warning "Repository '${Username}/${Project}' does not exist or is not accessible"
            }
            elseif ($result -match "already exists") {
                Write-Warning "Directory already exists and could not be removed"
            }
            elseif ($result -match "Permission denied") {
                Write-Warning "Permission denied. Check SSH key configuration."
            }
        }
    }
    catch {
        Write-Error "Unexpected error cloning repository '$Project': $($_.Exception.Message)"
    }
}

function Get-Ip {
    <#
    .SYNOPSIS
        Gets the local IP address.
    .DESCRIPTION
        Returns the IPv4 address of every connected adapter that has a default
        gateway, i.e. the address other machines on the network can reach.
    .EXAMPLE
        Get-Ip
        Returns "192.168.1.100" (example local IP)
    #>
    param()
    (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' }).IPv4Address.IPAddress
}

function Get-Storage {
    <#
    .SYNOPSIS
        Returns info on free and used storage space in the C:\ drive
    .DESCRIPTION
        ditto SYNOPSIS
    .LINK
        Be sure to check out more of my code experiments on https://github.com/17lxve
    #>
    param ()
    Get-PSDrive C
}

function n { 
    if ($args.Count -eq 0) {
        nvim.exe .
    } else {
        nvim.exe $args
    }
}

function win {
    if ($args.Count -eq 0) {
        winget update --all
    } else {
        winget install $args
    }
}

function search {
    <#
    .SYNOPSIS
        Builds a search-engine URL from a query and opens it in the default browser.
    .DESCRIPTION
        Thin wrapper over the `search` Rust CLI (settings\rust\search). A naked
        query uses the modifiable default engine (Google initially); engines are
        selectable per-call via flags, and `--set-default <engine>` persists a
        new default. Build it once with `cargo build --release`.
    .EXAMPLE
        search what is a monkey?      # default engine
    .EXAMPLE
        search -g rust lifetimes      # force Google for this call
    .EXAMPLE
        search --set-default google   # change the default engine
    #>
    & "$PSScriptRoot/../rust/search/target/release/search.exe" @args
}

function New-File {
    <#
    .SYNOPSIS
        Creates a file, or updates its timestamp if it already exists (like Unix touch).
    .PARAMETER Name
        The name of the file to create.
    .PARAMETER Path
        The directory where to create the file (default: current directory).
    .PARAMETER Extension
        The file extension to append, e.g. ".txt" (optional).
    .EXAMPLE
        New-File "test.txt"
        Creates a new file named test.txt
    .EXAMPLE
        New-File "document" -Extension ".md" -Path "C:\Docs"
        Creates document.md in C:\Docs directory
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[^<>:"|?*\\/]+$')]
        [string]
        $Name,

        [Parameter(Position = 1)]
        [string]
        $Path = ".",

        [Parameter(Position = 2)]
        [ValidatePattern('^\.[a-zA-Z0-9]+$')]
        [string]
        $Extension = ""
    )

    if ($Extension -and -not $Name.EndsWith($Extension)) {
        $Name += $Extension
    }
    $fullPath = Join-Path $Path $Name

    if (Test-Path -LiteralPath $fullPath) {
        (Get-Item -LiteralPath $fullPath).LastWriteTime = Get-Date
    }
    else {
        New-Item -Path $fullPath -ItemType File | Out-Null
        Write-Output "Created: $fullPath"
    }
}

function New-NodeApp {
    <#
    .SYNOPSIS
        Generates a new Node application.
    .DESCRIPTION
        New-NodeApp uses npx (or yarn dlx) to generate apps.
        The current options available are:
            - Expo : expo
            - React : react
            - Next : next
            - Svelte : svelte
            - Solid : solid
            - Qwik : qwik
            - Lit : lit
            - Vue : vue
            - Vite + Express : vite-express
            - Server template (abjshawty/server) : server
    .PARAMETER Framework
        Specify the framework you're going to use.
        For utility purposes, the options are shown in description 
    .PARAMETER Name
        Give a name to your project.
    .PARAMETER PackageManager
        npm or yarn (default: yarn).
    .NOTES
        This function works on Windows and Linux running PowerShell 7+
    .LINK
        Be sure to check out more of my code experiments on https://github.com/17lxve
    .EXAMPLE
        New-NodeApp react my_app
        Creates a React + TypeScript application with Vite
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $Framework,
        [Parameter()]
        [string]
        $Name = "",
        [Parameter()]
        [ValidateSet("npm", "yarn")]
        [string]
        $PackageManager = "yarn"
    )

    $dlx = if ($PackageManager -eq "npm") { "npx" } else { "yarn dlx" }
    $commands = @{
        "expo"         = "$dlx create-expo@latest ${Name}";
        "react"        = "$dlx create-vite@latest ${Name} --template react-ts";
        "svelte"       = "$dlx create-vite@latest ${Name} --template svelte-ts";
        "solid"        = "$dlx create-vite@latest ${Name} --template solid-ts";
        "qwik"         = "$dlx create-vite@latest ${Name} --template qwik-ts";
        "lit"          = "$dlx create-vite@latest ${Name} --template lit-ts";
        "next"         = "$dlx create-next-app@latest ${Name} --use-${PackageManager}";
        "vue"          = "$dlx create-vue@latest ${Name}";
        "vite-express" = "$dlx create-vite-express@latest ${Name}";
        "server"       = "gh repo create ${Name} --template abjshawty/server --private --clone";
        "help"         = "Get-Help New-NodeApp"
    }

    if (-not $commands.ContainsKey($Framework)) {
        Write-Error "Unknown framework '$Framework'. Available: $($commands.Keys -join ', ')"
        return
    }

    Write-Output "Starting...`n"
    # Run
    try {
        Invoke-Expression ($commands[$Framework])
    }
    catch {
        Write-Error "Bro, there was an error here: $($_.Exception.Message)"
    }
    finally {
        Write-Output "`nWe are finished here.`nGood luck, Voyager."
    }
}

function Open-Origin {
    <#
    .SYNOPSIS
        Opens the Git origin remote URL in the default browser.
    .DESCRIPTION
        Gets the origin remote URL from the current Git repository,
        converts it to HTTPS format if needed, and opens it in the default browser.
    .EXAMPLE
        Open-Origin
        Opens the current repository's GitHub page in the browser
    #>
    
    try {
        Write-Verbose "Attempting to open Git origin URL in browser"
        
        # Check if we're in a git repository
        $gitDir = git rev-parse --git-dir 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Not in a Git repository"
            Write-Warning "Navigate to a Git repository directory first"
            return
        }
        
        # Get origin remote URL
        $url = git remote get-url origin 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "No 'origin' remote found"
            Write-Warning "Available remotes:"
            git remote -v | Write-Warning
            return
        }
        
        Write-Verbose "Found origin URL: $url"
        
        # Convert to HTTPS if needed
        $https = Find-HTTPSUrl -url $url
        Write-Verbose "Converted to HTTPS: $https"
        
        # Get default browser path
        $browserPath = Get-DefaultBrowserPath
        if (-not $browserPath -or -not (Test-Path $browserPath)) {
            Write-Error "Default browser not found or not accessible"
            Write-Warning "Try setting a default browser or use 'b' alias directly"
            return
        }
        
        # Open URL in browser
        Write-Verbose "Opening URL: $https"
        & $browserPath $https
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Opened repository in browser: $https"
        }
        else {
            Write-Error "Failed to open browser"
            Write-Warning "Browser path: $browserPath"
            Write-Warning "URL: $https"
        }
    }
    catch {
        Write-Error "Unexpected error opening repository: $($_.Exception.Message)"
    }
}

function Open-DefaultBrowser {
    param(
        [string]$Url
    )
    $browser = Get-DefaultBrowserPath
    if ($Url) {
        & $browser $Url
    } else {
        & $browser
    }
}

function Push-Git {
    <#
    .SYNOPSIS
        Adds, commits, and pushes changes to Git repository.
    .DESCRIPTION
        Performs a complete Git workflow: add all changes, commit with message,
        and push to remote repository.
    .PARAMETER Message
        The commit message to use for the commit.
    .PARAMETER AddAll
        Add all changes including untracked files (default: true).
    .PARAMETER Push
        Push to remote repository (default: true).
    .PARAMETER Remote
        Remote repository name (default: origin).
    .EXAMPLE
        Push-Git "Fix bug in authentication"
        Adds all changes, commits with message, and pushes to remote
    .EXAMPLE
        Push-Git "WIP" -Push:$false
        Commits changes but doesn't push
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 200)]
        [string[]]
        $Message,
        
        [Parameter()]
        [switch]
        $AddAll = $true,
        
        [Parameter()]
        [switch]
        $Push = $true,
        
        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [string]
        $Remote = "origin"
    )
    
    try {
        Write-Verbose "Starting Git push workflow"
        
        # Validate and join message
        $commitMessage = $Message -join " "
        Write-Verbose "Commit message: $commitMessage"
        
        # Check message length
        if ($commitMessage.Length -gt 200) {
            Write-Warning "Commit message is quite long ($($commitMessage.Length) characters). Consider shortening it."
        }
        
        # Check if we're in a git repository
        $gitDir = git rev-parse --git-dir 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Not in a Git repository"
            Write-Warning "Navigate to a Git repository directory first"
            return
        }
        
        # Check for changes to commit
        $status = git status --porcelain 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to get Git status"
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Warning "No changes to commit"
            return
        }
        
        Write-Verbose "Changes detected:"
        $status | Write-Verbose
        
        # Add changes if requested
        if ($AddAll) {
            Write-Verbose "Adding all changes..."
            $addResult = git add . 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to add changes"
                Write-Warning "Git output: $addResult"
                return
            }
        }
        
        # Commit changes
        Write-Verbose "Committing changes..."
        $commitResult = git commit -m $commitMessage 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to commit changes"
            Write-Warning "Git output: $commitResult"
            
            if ($commitResult -match "nothing to commit") {
                Write-Warning "No changes were staged for commit"
            }
            elseif ($commitResult -match "empty commit message") {
                Write-Warning "Commit message cannot be empty"
            }
            return
        }
        
        Write-Output "Commit successful: $commitMessage"
        
        # Push changes if requested
        if ($Push) {
            # Check if there's a remote to push to
            $remotes = git remote 2>&1
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remotes)) {
                Write-Warning "No remote repository configured. Changes committed locally."
                return
            }
            
            # Check if specified remote exists
            $remoteExists = git remote | Where-Object { $_ -eq $Remote }
            if (-not $remoteExists) {
                Write-Error "Remote '$Remote' does not exist"
                Write-Warning "Available remotes: $(($remotes -split '\n') -join ', ')"
                return
            }
            
            # Get current branch
            $branch = git rev-parse --abbrev-ref HEAD 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Could not determine current branch. Skipping push."
                return
            }
            
            if ($branch -eq "HEAD") {
                Write-Warning "Not on any branch (detached HEAD). Cannot push."
                return
            }
            
            Write-Verbose "Current branch: $branch"
            Write-Verbose "Remote: $Remote"
            
            # Check if push would be force push
            $trackingBranch = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
            if ($LASTEXITCODE -eq 0 -and $trackingBranch) {
                $ahead = git rev-list --count --left-right '@{u}...HEAD' 2>$null
                if ($LASTEXITCODE -eq 0 -and $ahead -match '^\d+\s+(\d+)$') {
                    $commitsAhead = [int]$matches[1]
                    if ($commitsAhead -gt 10) {
                        Write-Warning "You are $commitsAhead commits ahead of remote. Consider pulling first."
                        $choice = Read-Host "Continue with push? (y/N)"
                        if ($choice -notmatch '^[Yy]') {
                            Write-Output "Push cancelled"
                            return
                        }
                    }
                }
            }
            
            # Push changes
            if ($PSCmdlet.ShouldProcess("$Remote/$branch", "Push commits")) {
                Write-Verbose "Pushing changes to remote..."
                $pushResult = git push $Remote $branch 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Output "Successfully pushed changes to remote"
                    Write-Output "Remote: $Remote, Branch: $branch"
                }
                else {
                    Write-Error "Failed to push changes to remote"
                    Write-Warning "Git output: $pushResult"
                    
                    if ($pushResult -match "Authentication failed") {
                        Write-Warning "Git authentication failed. Check your credentials."
                    }
                    elseif ($pushResult -match "no such remote") {
                        Write-Warning "Remote '$Remote' does not exist"
                    }
                    elseif ($pushResult -match "Updates were rejected") {
                        Write-Warning "Push rejected. Try pulling latest changes first: git pull $Remote $branch"
                    }
                    elseif ($pushResult -match "fatal: couldn't find remote ref") {
                        Write-Warning "Branch '$branch' may not exist on remote. Try: git push -u $Remote $branch"
                    }
                    
                    Write-Warning "Changes were committed locally but not pushed"
                }
            }
            else {
                Write-Output "Push cancelled (WhatIf mode)"
            }
        }
        else {
            Write-Output "Changes committed locally (push skipped)"
        }
    }
    catch {
        Write-Error "Unexpected error during Git push: $($_.Exception.Message)"
    }
}

function Remove-Folder {
    <#
    .SYNOPSIS
        Removes a folder and all its contents.
    .DESCRIPTION
        Asks for confirmation, then removes the folder recursively. Refuses
        drive roots, your user profile folder, and anything under Windows or
        Program Files.
    .PARAMETER Path
        The path to the folder to remove.
    .PARAMETER DryRun
        Show what would be deleted without actually deleting.
    .PARAMETER Force
        Skip the confirmation prompt.
    .EXAMPLE
        Remove-Folder "C:\temp\old-folder"
        Completely removes the old-folder directory
    .EXAMPLE
        Remove-Folder "temp" -DryRun
        Shows what would be deleted in temp folder
    #>
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
        [switch]
        $Force
    )

    process {
        $protected = @($env:WINDIR, $env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }

        foreach ($folderPath in $Path) {
            if (-not (Test-Path -LiteralPath $folderPath -PathType Container)) {
                Write-Error "Not a folder: $folderPath"
                continue
            }

            # Check the resolved path so relative paths get the same protection as absolute ones
            $fullPath = (Resolve-Path -LiteralPath $folderPath).ProviderPath.TrimEnd('\')
            $isRoot = $fullPath -eq ([IO.Path]::GetPathRoot($fullPath)).TrimEnd('\')
            $isProtected = $protected | Where-Object { $fullPath -eq $_ -or $fullPath.StartsWith("$_\", [StringComparison]::OrdinalIgnoreCase) }
            if ($isRoot -or $fullPath -eq $env:USERPROFILE -or $isProtected) {
                Write-Error "Refusing to remove: $fullPath"
                continue
            }

            $items = Get-ChildItem -LiteralPath $fullPath -Recurse -Force -ErrorAction SilentlyContinue
            $sizeMB = [math]::Round(($items | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
            $summary = "$fullPath ($($items.Count) items, $sizeMB MB)"

            if ($DryRun) {
                Write-Output "DRY RUN: Would remove $summary"
                continue
            }

            if (-not $Force) {
                $choice = Read-Host "Permanently delete $summary? (y/N)"
                if ($choice -notmatch '^[Yy]') {
                    Write-Output "Cancelled: $fullPath"
                    continue
                }
            }

            Remove-Item -LiteralPath $fullPath -Recurse -Force
            Write-Output "Removed: $fullPath"
        }
    }
}

function Search-History {
    <#
    .SYNOPSIS
        Searches PowerShell command history for specific text.
    .DESCRIPTION
        Searches through the saved PowerShell command history and returns
        commands that contain the specified search text.
    .PARAMETER search_text
        The text to search for in command history.
    .EXAMPLE
        Search-History "git"
        Returns all commands containing "git" from history
    #>
    param (
        [Parameter()]
        [string]
        $search_text
    )
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object { $_ -like "*${search_text}*" }    
}

function Set-LocationDev {
    <#
    .SYNOPSIS
        Changes directory to the development folder.
    .DESCRIPTION
        Navigates to the development directory defined in the $workspace variable
        (the folder that contains this settings repo).
    .PARAMETER Path
        Alternative path to navigate to (overrides $workspace).
    .EXAMPLE
        Set-LocationDev
        Changes to the development directory
    #>
    param(
        [Parameter()]
        [string]
        $Path = $workspace
    )
    Set-Location $Path
}

function sym { cmd.exe /c mklink /H $args }
function ls { eza --icons $args }
function lt { eza --icons --tree --level=2 $args }

<#
.SYNOPSIS
    Creates hard links and enhanced directory listings.

.DESCRIPTION
    sym: Creates hard links using cmd.exe mklink /H.
    ls: Enhanced directory listing with icons using eza.
    lt: Enhanced tree view listing with icons (2 levels deep) using eza.

.EXAMPLE
    sym link.txt target.txt
    Creates a hard link link.txt pointing at target.txt
    
    ls
    Shows current directory with icons
    
    lt
    Shows current directory as tree with icons (2 levels)
#>

function ssh-list {
    <#
    .SYNOPSIS
        Lists the host names defined in ~/.ssh/config.
    #>
    Select-String -Pattern "^Host\s+(\S+)" ~\.ssh\config | ForEach-Object { $_.Matches[0].Groups[1].Value }
}

function Update-NodeApp {
    <#
    .SYNOPSIS
        Updates Node.js dependencies to latest versions.
    .DESCRIPTION
        Uses npm-check-updates to update package.json dependencies
        to their latest versions while respecting version ranges.
    .EXAMPLE
        Update-NodeApp
        Updates all dependencies in package.json to latest versions
    #>
    npx npm-check-updates -u
}

# ============================================================================
# ALIASES (Alphabetical Order)
# ============================================================================

Set-Alias b Open-DefaultBrowser
Set-Alias bd Get-DefaultBrowserPath
Set-Alias cc claude
Set-Alias cd z
Set-Alias clone Get-GitSSH
Set-Alias connect Connect-Wifi
Set-Alias dev Set-LocationDev
Set-Alias disconnect Disconnect-Wifi
Set-Alias e explorer.exe
Set-Alias hist Search-History
Set-Alias init New-NodeApp
Set-Alias ip Get-Ip
Set-Alias key Find-WifiKey
Set-Alias keygen ssh-keygen
Set-Alias lzc lazycurl
Set-Alias lzd lazydocker
Set-Alias lzg lazygit
Set-Alias lzs lazysql
Set-Alias mklink sym
Set-Alias o Open-Origin
Set-Alias pid Find-FromPort
Set-Alias port Find-Port
Set-Alias push Push-Git
Set-Alias rl railway
Set-Alias rmdir Remove-Folder
Set-Alias ssh_url Find-HTTPSUrl
Set-Alias storage Get-Storage
Set-Alias touch New-File
Set-Alias update Update-NodeApp
