# Variables

$dev = ((Get-Item (split-path -parent  $MyInvocation.MyCommand.Definition)).parent.parent).FullName;

# Functions
Set-Alias glab-sf Push-Glab
function Push-Glab {
    param ()
    "LeVPSdeG'Lab-DLSI-2024" | clip.exe
    Write-Output "Once dialog appears, right-click or press Ctrl + V to paste password in"
    sftp root@31.187.72.224;
}
Set-Alias glab Connect-Glab
function Connect-Glab {
    param ()
    "LeVPSdeG'Lab-DLSI-2024" | clip.exe
    Write-Output "Once dialog appears, right-click or press Ctrl + V to paste password in"
    ssh root@31.187.72.224;

}

Set-Alias unlock Get-OfficeKey
function Get-OfficeKey {
    Invoke-RestMethod https://massgrave.dev/get | Invoke-Expression;
}

Set-Alias connect Connect-Wifi
function Connect-Wifi { # Write docs
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

Set-Alias disconnect Disconnect-Wifi
function Disconnect-Wifi { # Write docs
    param ()
    netsh.exe wlan disconnect
}

Set-Alias swap Edit-Policy
function Edit-Policy { # Write docs
    param (
            [Parameter()]
            [string]
            $u=$null
    )
    $a=Get-ExecutionPolicy
    if($null -eq $u){
        try {
            if ($a -eq "Restricted") {
                Set-ExecutionPolicy Unrestricted
                Write-Output 'Execution Policy Set To Unrestricted'
            }else {
                Set-ExecutionPolicy Restricted
                Write-Output 'Execution Policy Set To Restricted'
                Write-Output "u=$u"
            }
        }
        catch {
            Write-Output 'Please run terminal as admin or use option /x'
        }
    }else {
        try {
            if ($a -eq "Restricted") {
                Set-ExecutionPolicy Unrestricted -Scope CurrentUser
                Write-Output 'Execution Policy Set To Unrestricted'
            }else {
                Set-ExecutionPolicy Restricted -Scope CurrentUser
                Write-Output 'Execution Policy Set To Restricted'
            }
        }
        catch {
            Write-Output 'Please run terminal as admin or use option -u'
        }
    }
}

Set-Alias key Find-WifiKey
function Find-WifiKey {
    param (
        [Parameter()]
        [string]
        $name
    )
    Invoke-Expression "netsh wlan show profile $($name) key=clear | findstr Key"
}

Set-Alias ip Get-Ip
function Get-Ip { # Write docs
    param()
    $out = (ipconfig.exe | findstr.exe 'IPv4')
    Write-Output ($out | findstr.exe '\.1\.')
}

Set-Alias push Push-Git
function Push-Git { # Write docs
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $message
    )
    if($null -eq $message){
        Write-Output "Message is missing! Please add a message!"
    } else {
        git add *
        git commit -m "$message"
        git push
    }
}

Set-Alias dev Set-LocationDev
function Set-LocationDev {
    Set-Location $dev;
    # Write-Output $dev

}

Set-Alias mongors Set-MongoDBReplicaSet
function Set-MongoDBReplicaSet {
    # mongosh.exe --eval db.
    mongod --replSet rs0 --port 27017 --dbpath "C:\Program Files\MongoDB\Server\6.0\data"
}

Set-Alias touch New-File
function New-File { # Write docs
    param(
        [Parameter()]
        [string]
        $name
    )
    if($null -eq $name){
        Write-Output "No name provided"
    } elseif (Test-Path $name) {
        Write-Output "File already exists"
    } else {
        New-Item -Name $name
    }   
}

Set-Alias init New-NodeApp
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
        $Name=""
    )

    # Default options available
    $frameworks = @{
        "react"         = "npx create-vite@latest ${Name} -- --template react-ts";
        "svelte"        = "npx create-vite@latest ${Name} -- --template svelte-ts";
        "solid"         = "npx create-vite@latest ${Name} -- --template solid-ts";
        "qwik"          = "npx create-vite@latest ${Name} -- --template qwik-ts";
        "lit"           = "npx create-vite@latest ${Name} -- --template lit-ts";
        "react-no-vite" = "npx create-react-app@latest ${Name} --use-npm";
        "next"          = "npx create-next-app@latest ${Name} --use-npm";
        "vue"           = "npm init vue@latest ${Name}";
        "vite-express"  = "npx create-vite-express@latest ${Name}";
        "express"       = "git clone https://github.com/17lxve/server-js ${Name}";
        "express-ts"    = "git clone https://github.com/17lxve/server-ts ${Name}";
        "test"          = "Write-Output 'I survived 2023 just to die at GREYDAY'"
        "help"          = "Get-Help New-NodeApp"
    }
    Write-Output "Starting...`n"
    # Run
    try {
        Invoke-Expression $frameworks[$Framework]
    }
    catch {
        Write-Error "Bro, there was an error here: $($_.Exception.Message)"
    }
    finally {
        Write-Output "`nWe are finished here.`nGood luck, Voyager."
    }
}

Set-Alias run Invoke-JavaProgram
function Invoke-JavaProgram { # TODO
    param (
        [Parameter()]
            [string]
            $x
    )
    C:\Users\Timmy\Documents\jdk-16\bin\javac.exe $x".java"
    C:\Users\Timmy\Documents\jdk-16\bin\java.exe $x
    Remove-Item $x".class";
}

Set-Alias search Search-History
function Search-History { # Write docs
    param (
        [Parameter()]
        [string]
        $search_text
    )
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object { $_ -like "*${search_text}*" }    
}

Set-Alias poweroff Set-PowerOff
function Set-PowerOff { # TODO
    param()
    python C:\Users\Timmy\Documents\snippets\windows\go_to_bed.py
}

Set-Alias pum  Update-PythonModules
function Update-PythonModules { # TODO
    param()
    & $PSScriptRoot/update_python_modules.ps1
}

# Set-Alias ds4 C:\Users\Timmy\Documents\DS4Windows\DS4Windows.exe