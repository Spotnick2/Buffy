# Deployment is a separate user action. Build and check a package before invoking this.
param(
    # The live Forever client. Pass the _classic_beta_ AddOns folder to deploy to the beta client.
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns',
    [string]$Library = '', [string]$LibGlass = '',
    [string]$Lua = 'C:\Program Files (x86)\Lua\5.1\lua.exe'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $repo ('.work\deploy-' + [guid]::NewGuid().ToString('N'))
& (Join-Path $PSScriptRoot 'package.ps1') -Destination $stage -Library $Library -LibGlass $LibGlass -Lua $Lua
if ($LASTEXITCODE -ne 0) { throw 'Package build failed; deployment stopped.' }
$addons = [IO.Path]::GetFullPath($AddOnsPath)
$target = [IO.Path]::GetFullPath((Join-Path $addons 'Buffy'))
if ((Split-Path -Parent $target) -ne $addons.TrimEnd('\', '/')) { throw 'Invalid addon target.' }
New-Item -ItemType Directory -Path $target -Force | Out-Null
# Only Buffy-owned files are copied. No sibling addon or SavedVariables file is touched.
Copy-Item -Path (Join-Path $stage 'Buffy\*') -Destination $target -Recurse -Force
Write-Host "Deployed Buffy to $target"
