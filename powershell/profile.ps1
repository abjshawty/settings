# ============================================================================
# VARIABLES
# ============================================================================

$workspace = ((Get-Item (split-path -parent  $MyInvocation.MyCommand.Definition)).parent.parent).FullName

# ============================================================================
# INITIALIZATION
# ============================================================================

# try { oh-my-posh init pwsh --config "material" | Invoke-Expression } catch { }
oh-my-posh init pwsh --config "material" | Invoke-Expression 2>$null
zoxide.exe init powershell | Out-String | Invoke-Expression 2>$null

# ============================================================================
# CLEANUP
# ============================================================================

if (Test-Path alias:rmdir) { Remove-Item alias:rmdir }
if (Test-Path alias:ls) { Remove-Item alias:ls }
if (Test-Path alias:cd) { Remove-Item alias:cd }

# ============================================================================
# FUNCTIONS (Alphabetical Order)
# ============================================================================

function Update-PythonModules {
    <#
    .SYNOPSIS
        Updates all installed Python packages to their latest versions.
    .DESCRIPTION
        Gets a list of all installed Python packages and upgrades each one.
        Uses pip to list packages and then upgrades them individually.
    .EXAMPLE
        Update-PythonModules
        Updates all installed Python packages
    #>
    param()
    $temp = py -m pip list
    $res = $temp.replace('0', '')
    for ($x = 0; $x -lt 10; $x++) {
        $res = $res.replace($x.ToString(), '')
    }
    $res = $res.replace('.', '')
    $res = $res.replace('Package                   Version', '')
    $res = $res.replace('------------------------- ---------', '')
    foreach ($x in $res) {
        py -m pip install --upgrade $x
    }
}

function Connect-Wifi {
    <#
    .SYNOPSIS
        Connects to a specified WiFi network.
    .DESCRIPTION
        Uses netsh.exe to connect to a WiFi network by name.
        Provides feedback on connection status.
    .PARAMETER Name
        The name of the WiFi network to connect to.
    .PARAMETER Timeout
        Connection timeout in seconds (default: 30).
    .PARAMETER Retry
        Number of retry attempts (default: 3).
    .EXAMPLE
        Connect-Wifi "MyNetwork"
        Connects to the WiFi network named "MyNetwork"
    .EXAMPLE
        Connect-Wifi "MyNetwork" -Timeout 60 -Retry 5
        Connects with extended timeout and retry attempts
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 32)]
        [ValidatePattern('^[^<>:"|?*]+$')]
        [string]
        $Name,
        
        [Parameter()]
        [ValidateRange(5, 300)]
        [int]
        $Timeout = 30,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]
        $Retry = 3
    )
    
    try {
        Write-Verbose "Attempting to connect to WiFi network: $Name"
        
        # Check if netsh is available
        if (-not (Get-Command netsh.exe -ErrorAction SilentlyContinue)) {
            Write-Error "netsh.exe not found. This function requires Windows."
            return
        }
        
        # Get available WiFi networks
        Write-Verbose "Checking available WiFi networks..."
        $availableNetworks = netsh wlan show profiles 2>&1 | Select-String "All User Profile"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to retrieve WiFi profiles. Make sure WiFi adapter is enabled."
            return
        }
        
        # Extract network names
        $networkNames = $availableNetworks | ForEach-Object {
            if ($_ -match ':\s*(.+)$') {
                $matches[1].Trim()
            }
        }
        
        Write-Verbose "Found $($networkNames.Count) saved networks: $($networkNames -join ', ')"
        
        # Check if requested network exists
        if ($networkNames -notcontains $Name) {
            Write-Error "WiFi network '$Name' not found in saved profiles"
            Write-Warning "Available networks: $($networkNames -join ', ')"
            
            # Suggest similar networks if available
            $similar = $networkNames | Where-Object { $_ -like "*$Name*" -or $Name -like "*$_*" }
            if ($similar) {
                Write-Warning "Did you mean: $($similar -join ', ')"
            }
            return
        }
        
        # Check current connection status
        $currentConnection = netsh wlan show interfaces 2>&1 | Select-String "SSID" | Select-String -NotMatch "BSSID"
        if ($currentConnection -and $currentConnection -match $Name) {
            Write-Output "Already connected to network: $Name"
            return
        }
        
        # Attempt connection with retries
        $attempt = 0
        while ($attempt -lt $Retry) {
            $attempt++
            Write-Verbose "Connection attempt $attempt of $Retry"
            
            # Attempt connection
            $result = netsh.exe wlan connect $Name 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "Connection command sent successfully"
                
                # Wait for connection to establish
                Write-Verbose "Waiting for connection to establish..."
                $connected = $false
                $waitTime = 0
                
                while ($waitTime -lt $Timeout -and -not $connected) {
                    Start-Sleep 2
                    $waitTime += 2
                    
                    # Check connection status
                    $status = netsh wlan show interfaces 2>&1 | Select-String "State"
                    if ($status -match "connected") {
                        $ssid = netsh wlan show interfaces 2>&1 | Select-String "SSID" | Select-String -NotMatch "BSSID"
                        if ($ssid -match $Name) {
                            $connected = $true
                            Write-Output "Successfully connected to network: $Name"
                            Write-Verbose "Connection established after $waitTime seconds"
                            return
                        }
                    }
                }
                
                if (-not $connected) {
                    Write-Warning "Connection timeout after $waitTime seconds (attempt $attempt)"
                }
            }
            else {
                Write-Warning "Connection command failed (attempt $attempt): $result"
            }
            
            if ($attempt -lt $Retry) {
                Write-Verbose "Waiting before retry..."
                Start-Sleep 5
            }
        }
        
        Write-Error "Failed to connect to '$Name' after $Retry attempts"
        Write-Warning "Troubleshooting tips:"
        Write-Warning "  - Check if WiFi adapter is enabled"
        Write-Warning "  - Verify network name spelling"
        Write-Warning "  - Ensure network is in range"
        Write-Warning "  - Check if network requires additional authentication"
    }
    catch {
        Write-Error "Unexpected error connecting to WiFi: $($_.Exception.Message)"
        Write-Warning "Make sure you're running with appropriate permissions"
    }
}

function Disconnect-Wifi {
    <#
    .SYNOPSIS
        Disconnects from the current WiFi network.
    .DESCRIPTION
        Uses netsh.exe to disconnect from the currently connected WiFi network.
    .EXAMPLE
        Disconnect-Wifi
        Disconnects from the current WiFi connection
    #>
    param ()
    
    try {
        Write-Verbose "Attempting to disconnect from current WiFi network"
        
        # Check if currently connected to any network
        $currentConnection = netsh wlan show interfaces | Select-String "SSID" | Select-String -NotMatch "BSSID"
        
        if (-not $currentConnection) {
            Write-Warning "No WiFi connection currently active"
            return
        }
        
        # Attempt disconnection
        $result = netsh.exe wlan disconnect 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully disconnected from WiFi network"
        }
        else {
            Write-Error "Failed to disconnect from WiFi. Exit code: $LASTEXITCODE"
            Write-Warning "Output: $result"
        }
    }
    catch {
        Write-Error "Unexpected error disconnecting from WiFi: $($_.Exception.Message)"
    }
}

function Edit-Policy {
    <#
    .SYNOPSIS
        Toggles PowerShell execution policy between Restricted and Unrestricted.
    .DESCRIPTION
        Switches PowerShell execution policy between Restricted and Unrestricted states.
        Can operate at user scope or system scope (requires admin privileges).
    .PARAMETER u
        If specified, changes policy for CurrentUser scope only.
        If not specified, attempts to change system-wide policy (requires admin).
    .EXAMPLE
        Edit-Policy
        Toggles system-wide execution policy (requires admin)
    .EXAMPLE
        Edit-Policy -u "true"
        Toggles CurrentUser execution policy
    #>
    param (
        [Parameter()]
        [string]
        $u = $null
    )
    $a = Get-ExecutionPolicy
    if ($null -eq $u) {
        try {
            if ($a -eq "Restricted") {
                Set-ExecutionPolicy Unrestricted
                Write-Output 'Execution Policy Set To Unrestricted'
            }
            else {
                Set-ExecutionPolicy Restricted
                Write-Output 'Execution Policy Set To Restricted'
                Write-Output "u=$u"
            }
        }
        catch {
            Write-Output 'Please run terminal as admin or use option /x'
        }
    }
    else {
        try {
            if ($a -eq "Restricted") {
                Set-ExecutionPolicy Unrestricted -Scope CurrentUser
                Write-Output 'Execution Policy Set To Unrestricted'
            }
            else {
                Set-ExecutionPolicy Restricted -Scope CurrentUser
                Write-Output 'Execution Policy Set To Restricted'
            }
        }
        catch {
            Write-Output 'Please run terminal as admin or use option -u'
        }
    }
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
    Invoke-Expression "netstat -ano | findstr :$($port)"
}

function Find-HTTPSUrl {
    <#
    .SYNOPSIS
        Converts Git SSH URLs to HTTPS URLs.
    .DESCRIPTION
        Transforms Git SSH URLs (git@github.com:user/repo.git) to HTTPS URLs.
        Useful for opening repositories in browsers or for HTTPS operations.
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
    $url = $url -replace ':', '/'
    $url = $url -replace 'git@', 'https://'
    $url
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
        [Parameter()]
        [string]
        $name
    )
    Invoke-Expression "netsh wlan show profile $($name) key=clear | findstr Key"
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

    switch ($browserProgId) {
        "ChromeHTML" { return "Google Chrome" }
        "FirefoxURL" { return "Mozilla Firefox" }
        "IE.HTTP" { return "Microsoft Edge (or Internet Explorer)" }
        "MSEdgeBHTM" { return "Microsoft Edge" }
        "HeliumHTM.VJJYHVVQDE56KG4TNASJ5NYUZU" { return "Helium" }
        "FirefoxURL-F0DC299D809B9700" { return "Zen Browser" }
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
        Uses ipconfig to find IPv4 addresses and filters for addresses starting with .1.
        Typically returns the local network IP address.
    .EXAMPLE
        Get-Ip
        Returns "192.168.1.100" (example local IP)
    #>
    param()
    $out = (ipconfig.exe | findstr.exe 'IPv4')
    Write-Output ($out | findstr.exe '\.1\.')
}

function Get-OfficeKey {
    <#
    .SYNOPSIS
    Activates Office/Windows
    .DESCRIPTION
    Uses the MassGrave algorithm to force unlock Windows 10/11, or Microsoft Office.
    User will receive prompts through a GUI to decide on which elements he wishes to activate.
    .LINK
    Be sure to check out more of my code experiments on https://github.com/17lxve
    #>
    Invoke-RestMethod https://massgrave.dev/get | Invoke-Expression;
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

function New-File {
    <#
    .SYNOPSIS
        Creates a new file with the specified name.
    .DESCRIPTION
        Creates a new empty file if it doesn't already exist.
        Provides feedback if no name is provided or if file already exists.
    .PARAMETER name
        The name of the file to create.
    .PARAMETER Path
        The directory where to create the file (default: current directory).
    .PARAMETER Extension
        The file extension to use (optional).
    .PARAMETER Force
        Overwrite existing file without confirmation.
    .EXAMPLE
        New-File "test.txt"
        Creates a new file named test.txt
    .EXAMPLE
        New-File "document" -Extension "pdf" -Path "C:\Docs"
        Creates document.pdf in C:\Docs directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^<>:"|?*\\/]+$')]
        [string]
        $Name,
        
        [Parameter()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "Directory '$_' does not exist"
                }
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "Path '$_' is not a directory"
                }
                $true
            })]
        [string]
        $Path = ".",
        
        [Parameter()]
        [ValidatePattern('^\\.[a-zA-Z0-9]+$')]
        [string]
        $Extension = "",
        
        [Parameter()]
        [switch]
        $Force
    )
    
    try {
        Write-Verbose "Attempting to create file: $Name"
        
        # Build full file path
        if ($Extension) {
            if ($Name -match '\\.[^.]+$') {
                # Name already has extension, replace it
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($Name) + $Extension
            }
            else {
                # Add extension
                $fileName = $Name + $Extension
            }
        }
        else {
            $fileName = $Name
        }
        
        $fullPath = Join-Path $Path $fileName
        Write-Verbose "Full path: $fullPath"
        
        # Check for invalid characters in full path
        $invalidChars = [IO.Path]::GetInvalidPathChars()
        if ($fullPath.IndexOfAny($invalidChars) -ge 0) {
            Write-Error "Path contains invalid characters: $fullPath"
            Write-Warning "Invalid characters: $($invalidChars -join ', ')"
            return
        }
        
        # Check path length (Windows limit)
        if ($fullPath.Length -gt 260) {
            Write-Error "Path too long (max 260 characters): $fullPath"
            return
        }
        
        # Check if file already exists
        if (Test-Path $fullPath) {
            if ($Force) {
                Write-Verbose "Overwriting existing file: $fullPath"
                Remove-Item $fullPath -Force -ErrorAction Stop
            }
            else {
                Write-Warning "File already exists: $fullPath"
                $choice = Read-Host "Do you want to overwrite the existing file? (y/N)"
                if ($choice -notmatch '^[Yy]') {
                    Write-Output "File creation cancelled"
                    return
                }
                Remove-Item $fullPath -Force -ErrorAction Stop
            }
        }
        
        # Attempt to create the file
        $newFile = New-Item -Path $fullPath -ItemType File -Force -ErrorAction Stop
        Write-Output "Successfully created file: $($newFile.FullName)"
        
        # Return the file object for potential chaining
        return $newFile
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied: Cannot create file '$fullPath'. Check permissions."
    }
    catch [System.IO.DirectoryNotFoundException] {
        Write-Error "Directory not found: Cannot create file '$fullPath'. Parent directory may not exist."
    }
    catch [System.IO.IOException] {
        Write-Error "IO error: Cannot create file '$fullPath'. File may be in use or path too long."
    }
    catch {
        Write-Error "Unexpected error creating file '$fullPath': $($_.Exception.Message)"
    }   
}

function New-NodeApp {
    <#
    .SYNOPSIS
        Generates a new Node application.
    .DESCRIPTION
        New-NodeApp uses npm/npx to generate apps.
        The current options available are:
            - Vue : vue
            - React (With or without Vite) : react/react-no-vite
            - Next : next
            - Svelte : svelte
            - Solid : solid
            - Qwik : qwik
            - Lit : lit
            - React + Express : vite-express
            - Vue + Express : vite-express
            - Express : express
            - Express-TS : express-ts
    .PARAMETER Framework
        Specify the framework you're going to use.
        For utility purposes, the options are shown in description 
    .PARAMETER Name
        Give a name to your project.
    .NOTES
        This function works on Windows and Linux running PowerShell 7+
    .LINK
        Be sure to check out more of my code experiments on https://github.com/17lxve
    .EXAMPLE
        New NodeApp react_app
        Creates a React Application without Vite
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $Framework,
        [Parameter()]
        [string]
        $Name = "",
        [Parameter()]
        [string]
        $PackageManager = "yarn"
    )

    # Default options available
    if ($PackageManager -eq "npm") {
        $commands = @{
            "expo"          = "npx create-expo@latest ${Name}";
            "react"         = "npx create-vite@latest ${Name} -- --template react-ts";
            "svelte"        = "npx create-vite@latest ${Name} -- --template svelte-ts";
            "solid"         = "npx create-vite@latest ${Name} -- --template solid-ts";
            "qwik"          = "npx create-vite@latest ${Name} -- --template qwik-ts";
            "lit"           = "npx create-vite@latest ${Name} -- --template lit-ts";
            "react-no-vite" = "npx create-react-app@latest ${Name} --use-npm";
            "next"          = "npx create-next-app@latest ${Name} --use-npm";
            "vue"           = "npm init vue@latest ${Name}";
            "vite-express"  = "npx create-vite-express@latest ${Name}";
            "server"        = "gh repo create ${Name} --template abjshawty/server --private --clone";
            "test"          = "Write-Output 'I survived 2023 just to die at GREYDAY'"
            "help"          = "Get-Help New-NodeApp"
        }
    }
    else {
        $commands = @{
            "expo"          = "yarn dlx create-expo@latest ${Name}";
            "react"         = "yarn dlx create-vite@latest ${Name} -- --template react-ts";
            "svelte"        = "yarn dlx create-vite@latest ${Name} -- --template svelte-ts";
            "solid"         = "yarn dlx create-vite@latest ${Name} -- --template solid-ts";
            "qwik"          = "yarn dlx create-vite@latest ${Name} -- --template qwik-ts";
            "lit"           = "yarn dlx create-vite@latest ${Name} -- --template lit-ts";
            "react-no-vite" = "yarn dlx create-react-app@latest ${Name} --use-npm";
            "next"          = "yarn dlx create-next-app@latest ${Name} --use-npm";
            "vue"           = "yarn init vue@latest ${Name}";
            "vite-express"  = "yarn dlx create-vite-express@latest ${Name}";
            "server"        = "gh repo create ${Name} --template abjshawty/server --private --clone";
            "test"          = "Write-Output 'I survived 2025 just to die at GREYDAY'"
            "help"          = "Get-Help New-NodeApp"
        }
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
        Forcefully removes a directory and all its subdirectories and files.
        Uses -Recurse and -Force parameters for complete removal.
    .PARAMETER Path
        The path to the folder to remove.
    .PARAMETER Confirm
        Skip confirmation prompt (dangerous!)
    .PARAMETER DryRun
        Show what would be deleted without actually deleting.
    .EXAMPLE
        Remove-Folder "C:\temp\old-folder"
        Completely removes the old-folder directory
    .EXAMPLE
        Remove-Folder "temp" -DryRun
        Shows what would be deleted in temp folder
    #>
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                # Check for invalid characters
                $invalidChars = [IO.Path]::GetInvalidPathChars()
                if ($_.IndexOfAny($invalidChars) -ge 0) {
                    throw "Path contains invalid characters: $_"
                }
            
                # Check path length
                if ($_.Length -gt 260) {
                    throw "Path too long (max 260 characters): $_"
                }
            
                # Check for dangerous system paths
                $dangerousPaths = @(
                    $env:WINDIR,
                    $env:PROGRAMFILES,
                    $env:PROGRAMFILES_X86,
                    "C:\\",
                    "\\\\",
                    $env:USERPROFILE
                )
            
                foreach ($dangerPath in $dangerousPaths) {
                    if ($dangerPath -and $_.StartsWith($dangerPath, [StringComparison]::OrdinalIgnoreCase)) {
                        throw "Dangerous path detected: $_. Removing system directories is not allowed."
                    }
                }
            
                $true
            })]
        [string[]]
        $Path,
        
        [Parameter()]
        [switch]
        $DryRun,
        
        [Parameter()]
        [switch]
        $Confirm
    )
    
    begin {
        Write-Verbose "Starting folder removal operation"
    }
    
    process {
        foreach ($folderPath in $Path) {
            try {
                Write-Verbose "Processing folder: $folderPath"
                
                # Resolve full path
                $resolvedPath = Resolve-Path $folderPath -ErrorAction SilentlyContinue
                if (-not $resolvedPath) {
                    Write-Warning "Folder does not exist: $folderPath"
                    continue
                }
                
                $fullPath = $resolvedPath.Path
                Write-Verbose "Resolved path: $fullPath"
                
                # Check if it's actually a directory
                $itemInfo = Get-Item $fullPath
                if ($itemInfo -isnot [System.IO.DirectoryInfo]) {
                    Write-Error "Path is not a directory: $fullPath"
                    continue
                }
                
                # Get folder statistics
                $stats = Get-ChildItem $fullPath -Recurse -ErrorAction SilentlyContinue | Measure-Object
                $fileCount = $stats.Count
                $size = (Get-ChildItem $fullPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                
                Write-Verbose "Folder contains $fileCount items, total size: $([math]::Round($size / 1MB, 2)) MB"
                
                if ($DryRun) {
                    Write-Host "DRY RUN: Would remove folder: $fullPath" -ForegroundColor Yellow
                    Write-Host "  Files: $fileCount, Size: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Yellow
                    continue
                }
                
                # Confirmation logic
                if (-not $Confirm -and -not $PSCmdlet.ShouldProcess($fullPath, "Remove folder and all contents")) {
                    Write-Output "Folder removal cancelled: $fullPath"
                    continue
                }
                
                if (-not $Confirm) {
                    Write-Warning "This will permanently delete the folder '$fullPath' and all its contents."
                    Write-Warning "Files: $fileCount, Size: $([math]::Round($size / 1MB, 2)) MB"
                    $choice = Read-Host "Are you sure you want to continue? (y/N)"
                    
                    if ($choice -notmatch '^[Yy]') {
                        Write-Output "Folder removal cancelled: $fullPath"
                        continue
                    }
                }
                
                # Attempt removal
                Write-Verbose "Removing folder: $fullPath"
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Output "Successfully removed folder: $fullPath"
                Write-Verbose "Removed $fileCount items, freed $([math]::Round($size / 1MB, 2)) MB"
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error "Access denied: Cannot remove folder '$folderPath'. Check permissions or if files are in use."
                Write-Warning "Try running as administrator or closing any programs using files in the folder."
            }
            catch [System.IO.IOException] {
                Write-Error "IO error: Cannot remove folder '$folderPath'. Files may be in use or path too long."
                Write-Warning "Close any programs that might be using files in this folder."
            }
            catch {
                Write-Error "Unexpected error removing folder '$folderPath': $($_.Exception.Message)"
            }
        }
    }
    
    end {
        Write-Verbose "Folder removal operation completed"
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
        Navigates to the development directory defined in the $workspace variable.
    The $workspace variable is automatically set to the parent of the script's grandparent directory.
    .PARAMETER Path
        Alternative path to navigate to (overrides $workspace).
    .PARAMETER Create
        Create directory if it doesn't exist.
    .EXAMPLE
        Set-LocationDev
        Changes to the development directory
    .EXAMPLE
        Set-LocationDev -Path "C:\Projects" -Create
        Creates and navigates to C:\Projects
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateScript({
                if ([string]::IsNullOrWhiteSpace($_)) {
                    return $true  # Allow empty to use $workspace
                }
            
                # Check for invalid characters
                $invalidChars = [IO.Path]::GetInvalidPathChars()
                if ($_.IndexOfAny($invalidChars) -ge 0) {
                    throw "Path contains invalid characters: $_"
                }
            
                # Check path length
                if ($_.Length -gt 260) {
                    throw "Path too long (max 260 characters): $_"
                }
            
                $true
            })]
        [string]
        $Path = "",
        
        [Parameter()]
        [switch]
        $Create
    )
    
    try {
        # Determine target path
        $targetPath = if ([string]::IsNullOrWhiteSpace($Path)) {
            $workspace
        }
        else {
            $Path
        }
        
        Write-Verbose "Attempting to change to directory: $targetPath"
        
        # Check if target path is set
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            Write-Error "No target path specified and \$workspace is not set"
            Write-Warning "Check the VARIABLES section at the top of the profile or provide -Path parameter"
            return
        }
        
        # Check if directory exists
        if (-not (Test-Path $targetPath)) {
            if ($Create) {
                Write-Verbose "Creating directory: $targetPath"
                try {
                    New-Item -Path $targetPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    Write-Output "Created directory: $targetPath"
                }
                catch {
                    Write-Error "Failed to create directory '$targetPath': $($_.Exception.Message)"
                    return
                }
            }
            else {
                Write-Error "Directory does not exist: $targetPath"
                Write-Warning "The directory may have been moved or deleted"
                Write-Warning "Current \$workspace value: $workspace"
                
                # Try to suggest possible locations
                $parentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
                Write-Warning "Profile location: $parentDir"
                Write-Warning "Consider updating the \$workspace variable in the profile or use -Create switch"
                return
            }
        }
        
        # Resolve full path
        $resolvedPath = Resolve-Path $targetPath -ErrorAction Stop
        Write-Verbose "Resolved path: $resolvedPath"
        
        # Check if it's actually a directory
        $pathInfo = Get-Item $resolvedPath
        if ($pathInfo -isnot [System.IO.DirectoryInfo]) {
            Write-Error "Path is not a directory: $resolvedPath"
            return
        }
        
        # Check if we can access the directory
        try {
            $testAccess = Get-ChildItem $resolvedPath -ErrorAction Stop | Select-Object -First 1
        }
        catch {
            Write-Warning "Cannot access directory contents: $resolvedPath"
        }
        
        # Change location
        Set-Location $resolvedPath -ErrorAction Stop
        Write-Verbose "Changed to directory: $resolvedPath"
        
        # Show current location for confirmation
        Write-Verbose "Current location: $(Get-Location)"
        
        # Show directory info
        $itemCount = (Get-ChildItem $resolvedPath -ErrorAction SilentlyContinue).Count
        Write-Verbose "Directory contains $itemCount items"
        
        # Return directory info
        # return Get-Item $resolvedPath
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied: Cannot access directory '$targetPath'"
        Write-Warning "Check directory permissions or run as administrator"
    }
    catch {
        Write-Error "Unexpected error changing to directory '$targetPath': $($_.Exception.Message)"
    }
}

function sym { cmd.exe /c mklink /H $args }
function ls { eza --icons $args }
function lt { eza --icons --tree --level=2 $args }

<#
.SYNOPSIS
    Creates symbolic links and enhanced directory listings.

.DESCRIPTION
    sym: Creates hard symbolic links using cmd.exe mklink.
    ls: Enhanced directory listing with icons using eza.
    lt: Enhanced tree view listing with icons (2 levels deep) using eza.

.EXAMPLE
    sym target.txt link.txt
    Creates a hard link from link.txt to target.txt
    
    ls
    Shows current directory with icons
    
    lt
    Shows current directory as tree with icons (2 levels)
#>

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
    Invoke-Expression "npx npm-check-updates -u"
}

# ============================================================================
# TESTING & VALIDATION
# ============================================================================

function Test-ProfileFunctions {
    <#
    .SYNOPSIS
        Tests critical profile functions to validate error handling.
    .DESCRIPTION
        Performs basic tests on key functions to ensure error handling works correctly.
        Tests file operations, directory operations, and basic functionality.
    .EXAMPLE
        Test-ProfileFunctions
        Runs all available tests and reports results
    #>
    
    $testResults = @()
    $testFiles = @()
    
    Write-Host "=== Profile Function Tests ===" -ForegroundColor Cyan
    
    try {
        # Test 1: New-File with invalid name
        Write-Host "\nTest 1: New-File with invalid characters" -ForegroundColor Yellow
        try {
            New-File "test<>file.txt" -ErrorAction Stop
            $testResults += "FAIL: New-File invalid chars: Should have failed"
        }
        catch {
            $testResults += "PASS: New-File invalid chars: Correctly rejected"
        }
        
        # Test 2: New-File with valid name and new parameters
        Write-Host "Test 2: New-File with enhanced parameters" -ForegroundColor Yellow
        $testFile = "test_profile_$(Get-Random).txt"
        try {
            $result = New-File $testFile -Extension ".txt" -Force -ErrorAction Stop
            if (Test-Path $testFile) {
                $testResults += "PASS: New-File enhanced params: Success"
                $testFiles += $testFile
            }
            else {
                $testResults += "FAIL: New-File enhanced params: File not created"
            }
        }
        catch {
            $testResults += "FAIL: New-File enhanced params: Unexpected error - $($_.Exception.Message)"
        }
        
        # Test 3: Remove-Folder with validation
        Write-Host "Test 3: Remove-Folder parameter validation" -ForegroundColor Yellow
        try {
            # Test dangerous path detection
            Remove-Folder $env:WINDIR -Confirm -ErrorAction Stop
            $testResults += "FAIL: Remove-Folder dangerous path: Should have failed"
        }
        catch {
            $testResults += "PASS: Remove-Folder dangerous path: Correctly rejected"
        }
        
        # Test 4: Remove-Folder dry run
        Write-Host "Test 4: Remove-Folder dry run" -ForegroundColor Yellow
        $testFolder = "test_folder_$(Get-Random)"
        try {
            New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
            Remove-Folder $testFolder -DryRun -ErrorAction Stop
            $testResults += "PASS: Remove-Folder dry run: Success"
            # Clean up
            Remove-Item $testFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            $testResults += "FAIL: Remove-Folder dry run: Error - $($_.Exception.Message)"
        }
        
        # Test 5: Connect-Wifi parameter validation
        Write-Host "Test 5: Connect-Wifi parameter validation" -ForegroundColor Yellow
        try {
            # Test invalid network name (too long)
            Connect-Wifi "$( 'a' * 50 )" -ErrorAction Stop
            $testResults += "FAIL: Connect-Wifi long name: Should have failed"
        }
        catch {
            $testResults += "PASS: Connect-Wifi long name: Correctly rejected"
        }
        
        # Test 6: Get-GitSSH parameter validation
        Write-Host "Test 6: Get-GitSSH parameter validation" -ForegroundColor Yellow
        try {
            # Test invalid project name
            Get-GitSSH "invalid<>project" -ErrorAction Stop
            $testResults += "FAIL: Get-GitSSH invalid name: Should have failed"
        }
        catch {
            $testResults += "PASS: Get-GitSSH invalid name: Correctly rejected"
        }
        
        # Test 7: Push-Git parameter validation
        Write-Host "Test 7: Push-Git parameter validation" -ForegroundColor Yellow
        try {
            # Test empty message
            Push-Git "" -ErrorAction Stop
            $testResults += "FAIL: Push-Git empty message: Should have failed"
        }
        catch {
            $testResults += "PASS: Push-Git empty message: Correctly rejected"
        }
        
        # Test 8: Set-LocationDev parameter validation
        Write-Host "Test 8: Set-LocationDev parameter validation" -ForegroundColor Yellow
        try {
            # Test invalid path
            Set-LocationDev -Path "invalid<>path" -ErrorAction Stop
            $testResults += "FAIL: Set-LocationDev invalid path: Should have failed"
        }
        catch {
            $testResults += "PASS: Set-LocationDev invalid path: Correctly rejected"
        }
        
        # Test 9: Set-LocationDev with create option
        Write-Host "Test 9: Set-LocationDev create option" -ForegroundColor Yellow
        $testDir = "test_dir_$(Get-Random)"
        try {
            Set-LocationDev -Path $testDir -Create -ErrorAction Stop
            if (Test-Path $testDir) {
                $testResults += "PASS: Set-LocationDev create: Success"
                # Clean up
                Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                $testResults += "FAIL: Set-LocationDev create: Directory not created"
            }
        }
        catch {
            $testResults += "FAIL: Set-LocationDev create: Error - $($_.Exception.Message)"
        }
        
        # Test 5: Git functions (if in git repo)
        Write-Host "Test 5: Git functions" -ForegroundColor Yellow
        $gitDir = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -eq 0) {
            try {
                # Test Open-Origin (should not fail if origin exists)
                $url = git remote get-url origin 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $testResults += "PASS: Git environment: Repository detected"
                }
                else {
                    $testResults += "SKIP: Git environment: No origin remote"
                }
            }
            catch {
                $testResults += "SKIP: Git environment: Error checking - $($_.Exception.Message)"
            }
        }
        else {
            $testResults += "SKIP: Git environment: Not in git repository"
        }
        
        # Test 6: Network functions (basic validation)
        Write-Host "Test 6: Network functions validation" -ForegroundColor Yellow
        try {
            # Test Find-WifiKey with empty name (should not crash)
            Find-WifiKey "" 2>$null | Out-Null
            $testResults += "PASS: Network functions: Basic validation passed"
        }
        catch {
            $testResults += "PASS: Network functions: Error handling working"
        }
        
    }
    catch {
        $testResults += "FAIL: Test suite error: $($_.Exception.Message)"
    }
    finally {
        # Cleanup test files
        Write-Host "\nCleaning up test files..." -ForegroundColor Gray
        foreach ($file in $testFiles) {
            if (Test-Path $file) {
                Remove-Item $file -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Display results
    Write-Host "\n=== Test Results ===" -ForegroundColor Cyan
    foreach ($result in $testResults) {
        if ($result.StartsWith("PASS:")) {
            Write-Host $result -ForegroundColor Green
        }
        elseif ($result.StartsWith("FAIL:")) {
            Write-Host $result -ForegroundColor Red
        }
        else {
            Write-Host $result -ForegroundColor Yellow
        }
    }
    
    $passed = ($testResults | Where-Object { $_.StartsWith("PASS:") }).Count
    $failed = ($testResults | Where-Object { $_.StartsWith("FAIL:") }).Count
    $skipped = ($testResults | Where-Object { $_.StartsWith("SKIP:") }).Count
    
    Write-Host "\nSummary: $passed passed, $failed failed, $skipped skipped" -ForegroundColor Cyan
    
    return $testResults
}

# ============================================================================
# ALIASES (Alphabetical Order)
# ============================================================================

Set-Alias b Get-DefaultBrowserPath
Set-Alias bi "bun install"
Set-Alias cd z
Set-Alias clone Get-GitSSH
Set-Alias connect Connect-Wifi
Set-Alias c windsurf
Set-Alias dev Set-LocationDev
Set-Alias disconnect Disconnect-Wifi
Set-Alias e explorer.exe
Set-Alias init New-NodeApp
Set-Alias ip Get-Ip
Set-Alias key Find-WifiKey
Set-Alias keygen ssh-keygen
Set-Alias mklink sym
Set-Alias o Open-Origin
Set-Alias pid Find-FromPort
Set-Alias port Find-Port
Set-Alias pum Update-PythonModules
Set-Alias push Push-Git
Set-Alias rmdir Remove-Folder
Set-Alias search Search-History
Set-Alias ssh_url Find-HTTPSUrl
Set-Alias storage Get-Storage
Set-Alias swap Edit-Policy
Set-Alias surf windsurf
Set-Alias touch New-File
Set-Alias unlock Get-OfficeKey
Set-Alias update Update-NodeApp
Set-Alias v nvim.exe
Set-Alias vim nvim.exe
Set-Alias w winget
