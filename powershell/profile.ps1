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
    param ()
    netsh.exe wlan disconnect
}

function Edit-Policy {
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
    param(
        [Parameter()]
        [string]
        $port
    )
    Invoke-Expression "netstat -ano | findstr :$($port)"
}

function Find-HTTPSUrl {
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
    param(
        [Parameter(Mandatory)]
        [string]
        $processId
    )
    (Get-NetTcpConnection -OwningProcess $processId | Select-Object LocalPort).LocalPort
}

function Find-WifiKey {
    param (
        [Parameter()]
        [string]
        $name
    )
    Invoke-Expression "netsh wlan show profile $($name) key=clear | findstr Key"
}

function Get-DefaultBrowserName {
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
    $browserRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
    $browserProgId = (Get-ItemProperty $browserRegPath).ProgId
    $regPath = "Registry::HKEY_CLASSES_ROOT\$browserProgId\shell\open\command"
    $browserObj = Get-ItemProperty $regPath
    # Extract just the executable path from the command string
    $browserObj.'(default)' -replace '^"([^"]+)".*$', '$1' -replace '^([^\s]+).*$', '$1'
}

function Get-GitSSH {
    param (
        [Parameter(Mandatory)]
        [string]
        $project
    )
    $command = "git clone git@github.com:abjshawty/${project}.git";
    Invoke-Expression $command;
}

function Get-Ip {
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
    $url = git remote get-url origin
    $https = Find-HTTPSUrl -url $url
    & (Get-DefaultBrowserPath) $https
}

function Push-Git {
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
    param(
        [Parameter(Mandatory)]
        [string]
        $item
    )
    Remove-Item -Recurse -Force $item;
}

function Search-History {
    param (
        [Parameter()]
        [string]
        $search_text
    )
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object { $_ -like "*${search_text}*" }    
}

function Set-LocationDev {
    Set-Location $dev;
}

function sym { cmd.exe /c mklink /H $args }
function ls { eza --icons $args }
function lt { eza --icons --tree --level=2 $args }

function Update-NodeApp {
    Invoke-Expression "npx npm-check-updates -u"
}

function Update-PythonModules {
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
