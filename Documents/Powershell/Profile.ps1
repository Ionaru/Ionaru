function Set-Hosts {
    code C:\Windows\System32\drivers\etc\hosts
}

function Update-NPMModules {
    npm-check -uy
    Remove-Item node_modules -Recurse
    Remove-Item package-lock.json
    npm install
}

function Update-NPMLockfile {
    Remove-Item node_modules -Recurse
    Remove-Item package-lock.json
    npm install
}

Set-Alias -Name npmu -Value Update-NPMModules
Set-Alias -Name npmr -Value Update-NPMLockfile
Set-Alias -Name hosts -Value Set-Hosts

$ConfigFolder = (get-item $PROFILE.CurrentUserAllHosts).Directory.FullName

$PlatformExtensionsFile = "$ConfigFolder\PlatformExtensions.ps1"
if (Test-Path -Path $PlatformExtensionsFile -PathType Leaf) {
    Write-Output "Loading $PlatformExtensionsFile"
    .$PlatformExtensionsFile
}

Invoke-Expression (&starship init powershell)
