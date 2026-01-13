# ============================================================================
# VARIABLES
# ============================================================================

$dev = ((Get-Item (split-path -parent  $MyInvocation.MyCommand.Definition)).parent.parent).FullName

# ============================================================================
# INITIALIZATION
# ============================================================================

try { oh-my-posh init pwsh --config "material" | Invoke-Expression } catch { }

# ============================================================================
# CLEANUP
# ============================================================================

if (Test-Path alias:rmdir) { Remove-Item alias:rmdir }
if (Test-Path alias:ls) { Remove-Item alias:ls }

# ============================================================================
# FUNCTIONS (Alphabetical Order)
# ============================================================================

function Connect-Wifi {
    <#
    .SYNOPSIS
        Connects to a specified WiFi network.
    .DESCRIPTION
        Uses netsh.exe to connect to a WiFi network by name.
        Provides feedback on connection status.
    .PARAMETER name
        The name of the WiFi network to connect to.
    .EXAMPLE
        Connect-Wifi "MyNetwork"
        Connects to the WiFi network named "MyNetwork"
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $name
    )
    try {
        netsh.exe wlan connect $name
        Write-Output 'Connected to network'
    }
    catch {
        Write-Output 'Err'
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
    netsh.exe wlan disconnect
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
        "IE.HTTP"    { return "Microsoft Edge (or Internet Explorer)" }
        "MSEdgeBHTM" { return "Microsoft Edge" }
        "HeliumHTM.VJJYHVVQDE56KG4TNASJ5NYUZU" { return "Helium"}
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
    $browserObj.'(default)' -replace '^"([^"]+)".*$', '$1' -replace '^([^\s]+).*$', '$1'
}

function Get-GitSSH {
    <#
    .SYNOPSIS
        Clones a repository from GitHub using SSH.
    .DESCRIPTION
        Creates a git clone command for the specified repository from the abjshawty GitHub account.
        Uses SSH protocol for cloning.
    .PARAMETER project
        The name of the repository to clone (without .git extension).
    .EXAMPLE
        Get-GitSSH "my-repo"
        Clones git@github.com:abjshawty/my-repo.git
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $project
    )
    $command = "git clone git@github.com:abjshawty/${project}.git";
    Invoke-Expression $command;
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
    .EXAMPLE
        New-File "test.txt"
        Creates a new file named test.txt
    #>
    param(
        [Parameter()]
        [string]
        $name
    )
    if ($null -eq $name) {
        Write-Output "No name provided"
    }
    elseif (Test-Path $name) {
        Write-Output "File already exists"
    }
    else {
        New-Item -Name $name
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
    $frameworks_npm = @{
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
    $frameworks_yarn = @{
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
    Write-Output "Starting...`n"
    # Run
    try {
        $variableName = "frameworks_$PackageManager"
        Write-Output $variableName
        Invoke-Expression ((Get-Variable $variableName).Value[$Framework])
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
    $url = git remote get-url origin
    $https = Find-HTTPSUrl -url $url
    & (Get-DefaultBrowserPath) $https
}

function Push-Git {
    <#
    .SYNOPSIS
        Adds, commits, and pushes changes to Git repository.
    .DESCRIPTION
        Performs a complete Git workflow: add all changes, commit with message,
        and push to remote repository.
    .PARAMETER message
        The commit message to use for the commit.
    .EXAMPLE
        Push-Git "Fix bug in authentication"
        Adds all changes, commits with message, and pushes to remote
    #>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $message
    )
    if ($null -eq $message) {
        Write-Output "Message is missing! Please add a message!"
    }
    else {
        git add *
        git commit -m "$message"
        git push
    }
}

function Remove-Folder {
    <#
    .SYNOPSIS
        Removes a folder and all its contents.
    .DESCRIPTION
        Forcefully removes a directory and all its subdirectories and files.
        Uses -Recurse and -Force parameters for complete removal.
    .PARAMETER item
        The path to the folder to remove.
    .EXAMPLE
        Remove-Folder "C:\temp\old-folder"
        Completely removes the old-folder directory
    #>
    param(
        [Parameter(Mandatory)]
        [string]
        $item
    )
    Remove-Item -Recurse -Force $item;
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
        Navigates to the development directory defined in the $dev variable.
    The $dev variable is automatically set to the parent of the script's grandparent directory.
    .EXAMPLE
        Set-LocationDev
        Changes to the development directory
    #>
    Set-Location $dev;
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

function Update-PythonModules {
    <#
    .SYNOPSIS
        Updates Python modules using a separate script.
    .DESCRIPTION
        Executes the update_python_modules.ps1 script located in the same directory
        as this profile to update Python packages and modules.
    .EXAMPLE
        Update-PythonModules
        Runs the Python module update script
    #>
    param()
    & $PSScriptRoot/update_python_modules.ps1
}

# ============================================================================
# ALIASES (Alphabetical Order)
# ============================================================================

Set-Alias b Get-DefaultBrowserPath
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
