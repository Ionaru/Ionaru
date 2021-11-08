$ConfigFolder = (get-item $PROFILE.CurrentUserAllHosts).Directory.FullName

function Set-Hosts {
    # Open the Windows hostsfile in VSCode.
    code C:\Windows\System32\drivers\etc\hosts
}

function Set-PowerShellConfig {
    # Open the powershell config folder in VSCode.
    code $ConfigFolder
}

function Update-NPMModules {
    # Updates, then removes the node_modules folder and package-lock.json, then installs packages again (hard update).
    npm-check -uy
    Remove-Item node_modules -Recurse
    Remove-Item package-lock.json
    npm install
}

function Update-NPMLockfile {
    # Removes the node_modules folder and package-lock.json, then installs packages again (soft update).
    Remove-Item node_modules -Recurse
    Remove-Item package-lock.json
    npm install
}

function Get-TypedNPMPackage {
    # Installs an npm module and its @types/ package.
    Param(
      [Parameter(Mandatory=$true)]
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
      [Parameter(Mandatory=$true)]
      [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
      (Get-Item -Path $Path).LastWriteTime = Get-Date
    } else {
      New-Item -Type File -Path $Path
    }
}

function Get-MyRepo {
    Param(
      [Parameter(Mandatory=$true)]
      [string]$Repo
    )

    git clone https://github.com/Ionaru/$Repo
}

Set-Alias -Name npmu -Value Update-NPMModules
Set-Alias -Name npmr -Value Update-NPMLockfile
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
    Write-Output "Loading $PlatformExtensionsFile"
    .$PlatformExtensionsFile
}

Invoke-Expression (&starship init powershell)
