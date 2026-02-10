function Install-AppsFromList {
    <#
    .SYNOPSIS
        Installs all applications from the apps.md list using winget.
    .DESCRIPTION
        Reads the apps.md file and installs each application using winget with exact ID matching.
        Skips empty lines and comments.
    .PARAMETER AppsFile
        Path to the apps.md file (default: data/apps.md relative to settings directory)
    .EXAMPLE
        Install-AppsFromList
        Installs all apps from the default apps.md file
    .EXAMPLE
        Install-AppsFromList -AppsFile "custom_apps.txt"
        Installs apps from a custom file
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $AppsFile = "data/apps.md"
    )
    
    try {
        Write-Host "Starting application installation from: $AppsFile" -ForegroundColor Green
        
        # Get the settings directory (parent of powershell directory)
        $settingsDir = Split-Path (Split-Path $MyInvocation.MyCommand.Definition) -Parent
        $appsFilePath = Join-Path $settingsDir $AppsFile
        
        if (-not (Test-Path $appsFilePath)) {
            Write-Error "Apps file not found: $appsFilePath"
            return
        }
        
        # Read all lines from the apps file
        $appLines = Get-Content $appsFilePath
        
        # Filter out empty lines and comments
        $appsToInstall = $appLines | Where-Object { 
            $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") 
        }
        
        Write-Host "Found $($appsToInstall.Count) applications to install" -ForegroundColor Yellow
        
        # Install each app
        foreach ($appId in $appsToInstall) {
            $appId = $appId.Trim()
            Write-Host "Installing: $appId" -ForegroundColor Cyan
            
            try {
                winget install --id="$appId" --exact --accept-source-agreements --accept-package-agreements
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Successfully installed: $appId" -ForegroundColor Green
                }
                else {
                    Write-Warning "✗ Failed to install: $appId (Exit code: $LASTEXITCODE)"
                }
            }
            catch {
                Write-Error "✗ Error installing $appId`: $($_.Exception.Message)"
            }
            
            # Add a small delay between installations
            Start-Sleep -Seconds 2
        }
        
        Write-Host "Application installation process completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install applications: $($_.Exception.Message)"
    }
}

function Initialize-Environment {
    <#
    .SYNOPSIS
        Initializes the development environment with all required applications.
    .DESCRIPTION
        Sets up the development environment by installing all apps from the list
        and loading the PowerShell profile.
    .EXAMPLE
        Initialize-Environment
        Installs all apps and loads the PowerShell profile
    #>
    param()
    
    Write-Host "Initializing development environment..." -ForegroundColor Magenta
    
    # Install all applications
    Install-AppsFromList
    
    # Load PowerShell profile
    $profilePath = Join-Path (Split-Path $MyInvocation.MyCommand.Definition) "profile.ps1"
    if (Test-Path $profilePath) {
        Write-Host "Loading PowerShell profile..." -ForegroundColor Yellow
        . $profilePath
    }
    else {
        Write-Warning "PowerShell profile not found at: $profilePath"
    }
    
    Write-Host "Environment initialization completed!" -ForegroundColor Magenta
}

Initialize-Environment;