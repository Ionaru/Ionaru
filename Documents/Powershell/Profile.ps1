$ConfigFolder = (get-item $PROFILE.CurrentUserAllHosts).Directory.FullName

Function Test-CommandExists
{
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try { if (Get-Command $command) { RETURN $true } }
    Catch {
        Write-Host "Command '$command' not found" -ForegroundColor Yellow
        RETURN $false
    }
    Finally { $ErrorActionPreference = $oldPreference }
}

function Update-All {
    if (Test-CommandExists scoop) {
        Write-Host "Updating scoop packages..." -ForegroundColor Green
        scoop update
        scoop update *
        scoop cleanup *
    }
    if (Test-CommandExists npx) {
        Write-Host "Checking for updated npm packages..." -ForegroundColor Green
        $updateCommand = npx ncu -g | Select-Object -Last 2
        # if starts with npm
        if ($updateCommand -like "npm -g install *") {
            Write-Output $updateCommand[0]
            Invoke-Expression $updateCommand[0]
        }
        else {
            Write-Host "Global npm packages are up-to-date!" -ForegroundColor Green
        }
    }

    Write-Host "All done!" -ForegroundColor Green
}

function Set-Hosts {
    # Open the Windows hostsfile in VSCode.
    code C:\Windows\System32\drivers\etc\hosts
}

function Set-PowerShellConfig {
    # Open the powershell config folder in VSCode.
    code $ConfigFolder
}

function Update-NPMLockfile {
    # Removes the node_modules folder and package-lock.json, then installs packages again (soft update).
    Remove-Item node_modules -Recurse
    Remove-Item package-lock.json
    npm install
}

function Update-NPMModules {
    # Updates, then removes the node_modules folder and package-lock.json, then installs packages again (hard update).
    ncu -u
    Update-NPMLockfile
}

function Update-NPMCleanLockfile {
    # Removes the node_modules folder and package-lock.json, then installs packages again (soft update).
    npm cache clean --force
    Update-NPMLockfile
}

function Get-InstalledGlobalNPMPackages {
    # Returns a list of all globally installed NPM packages.
    npm list -g --depth=0
}

function Get-InstalledNPMPackages {
    # Returns a list of all installed NPM packages.
    npm list --depth=0
}

function Get-TypedNPMPackage {
    # Installs an npm module and its @types/ package.
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Module
    )

    npm i $Module
    npm i -D @types/$Module
}

function Open-Terminal {
    # Open a new terminal window in the same directory.
    wt --startingDirectory .
}

function Open-TerminalTab {
    # Open a new terminal tab in the same directory.
    wt --window 0 new-tab --startingDirectory .
}

function Open-TerminalPane {
    # Open a new terminal split-pane in the same directory.
    wt --window 0 split-pane --startingDirectory .
}

function Set-FileTouched {
    # Creates a file, or updates its 'last edited' value.
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
      (Get-Item -Path $Path).LastWriteTime = Get-Date
    }
    else {
        New-Item -Type File -Path $Path
    }
}

function Get-MyRepo {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Repo
    )

    git clone https://github.com/Ionaru/$Repo
}

Set-Alias -Name test -Value Test-CommandExists
Set-Alias -Name upgrade -Value Update-All
Set-Alias -Name npmu -Value Update-NPMModules
Set-Alias -Name npmr -Value Update-NPMLockfile
Set-Alias -Name npmcr -Value Update-NPMCleanLockfile
Set-Alias -Name npmls -Value Get-InstalledNPMPackages
Set-Alias -Name npmgls -Value Get-InstalledGlobalNPMPackages
Set-Alias -Name hosts -Value Set-Hosts
Set-Alias -Name psedit -Value Set-PowerShellConfig
Set-Alias -Name term -Value Open-Terminal
Set-Alias -Name tab -Value Open-TerminalTab
Set-Alias -Name nt -Value Open-TerminalTab
Set-Alias -Name split -Value Open-TerminalPane
Set-Alias -Name np -Value Open-TerminalPane
Set-Alias -Name npmit -Value Get-TypedNPMPackage
Set-Alias -Name touch -Value Set-FileTouched
Set-Alias -Name clone -Value Get-MyRepo

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

$PlatformExtensionsFile = "$ConfigFolder\PlatformExtensions.ps1"
if (Test-Path -Path $PlatformExtensionsFile -PathType Leaf) {
    Write-Host "Loading $PlatformExtensionsFile"
    .$PlatformExtensionsFile
}

if (Test-CommandExists starship) {
    Invoke-Expression (&starship init powershell)
} else {
    Write-Host "Starship prompt not installed: https://starship.rs/" -ForegroundColor Red
}

if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
} else {
    Write-Host "Posh git not installed: https://github.com/dahlbyk/posh-git" -ForegroundColor Red
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
} else {
    Write-Host "Terminal icons not installed: https://github.com/devblackops/Terminal-Icons" -ForegroundColor Red
}
