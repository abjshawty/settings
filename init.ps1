$PROFILE = "$(split-path  $MyInvocation.MyCommand.Definition)\powershell "
$deps = @(
    "gcc","python", "jdk20", "jdk8", "oraclejdk", "kotlinc","rust","nvm",   # Dev
    "vim", "git", "xampp-81", "docker-desktop", "figma", "scenebuilder",    # Dev
    "vscode", "microsoft-windows-terminal", "mongodb", "postgresql",        # Dev
    "mongodb-compass", "postman", "putty", "nmap", "flutter", "php",        # Dev
    "php", "sql-server-express",                                            # Dev
    "reaper", "spotify", "aimp", "vlc", "lilypond", "frescobaldi"           # Music
    "notion", "brave", "discord", "sharpkeys",                              # General
)

# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Set-ExecutionPolicy Bypass -Scope Process -Force; # Avoid permission-based errors
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression; # Install Chocolatey
. $PROFILE
foreach ($dependency in $deps) {
    choco install $dependency -y
}

