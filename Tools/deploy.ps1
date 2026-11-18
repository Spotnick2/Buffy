# Deployment is a separate user action. Build and check a package before invoking this.
#   pwsh Tools\deploy.ps1 -Library <LibGroupBuffs> -LibGlass <LibGlass>          Buffy only
#   pwsh Tools\deploy.ps1 -Library ... -LibGlass ... -Probe                      also ForeverProbe and BuffyProbe
# With -Probe: /reload in game, then /fp steps bf pin (or /fp bf).
param(
    # The live Forever client. The beta (_classic_beta_) is closed.
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns',
    [string]$Library = '', [string]$LibGlass = '',
    [string]$Lua = 'C:\Program Files (x86)\Lua\5.1\lua.exe',
    [switch]$Probe
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$addons = [IO.Path]::GetFullPath($AddOnsPath)

# The probe is checked before anything is copied, so a broken probe leaves Buffy untouched.
$probeDir = Join-Path $PSScriptRoot 'BuffyProbe'
$probeFiles = @('BuffyProbe.toc', 'BuffyProbe.lua')
$foreverProbe = if ($env:FOREVERPROBE) { $env:FOREVERPROBE } else { Join-Path (Split-Path -Parent $repo) 'ForeverProbe' }
if ($Probe) {
    foreach ($f in $probeFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $probeDir $f))) { throw "Missing probe file: $f" }
    }
    $luac = Join-Path (Split-Path -Parent $Lua) 'luac.exe'
    if (Test-Path -LiteralPath $luac) {
        & $luac -p (Join-Path $probeDir 'BuffyProbe.lua')
        if ($LASTEXITCODE -ne 0) { throw 'luac -p failed on BuffyProbe.lua' }
        Remove-Item -LiteralPath 'luac.out' -ErrorAction SilentlyContinue
    } else {
        Write-Host "  luac -p SKIPPED (no $luac)" -ForegroundColor Yellow
    }
    if (-not (Test-Path -LiteralPath (Join-Path $foreverProbe 'Tools\deploy.ps1'))) {
        throw "ForeverProbe checkout not found at $foreverProbe (or set `$env:FOREVERPROBE)"
    }
}

$stage = Join-Path $repo ('.work\deploy-' + [guid]::NewGuid().ToString('N'))
& (Join-Path $PSScriptRoot 'package.ps1') -Destination $stage -Library $Library -LibGlass $LibGlass -Lua $Lua
if ($LASTEXITCODE -ne 0) { throw 'Package build failed; deployment stopped.' }
$target = [IO.Path]::GetFullPath((Join-Path $addons 'Buffy'))
if ((Split-Path -Parent $target) -ne $addons.TrimEnd('\', '/')) { throw 'Invalid addon target.' }
New-Item -ItemType Directory -Path $target -Force | Out-Null
# Only Buffy-owned files are copied. No sibling addon or SavedVariables file is touched.
Copy-Item -Path (Join-Path $stage 'Buffy\*') -Destination $target -Recurse -Force
Write-Host "Deployed Buffy to $target"

if ($Probe) {
    # The host first, with its own deploy; it refuses an incomplete checkout.
    & pwsh -NoProfile -File (Join-Path $foreverProbe 'Tools\deploy.ps1') -AddOnsPath $addons
    if ($LASTEXITCODE -ne 0) { throw 'ForeverProbe deploy refused; BuffyProbe was not copied' }
    $probeTarget = Join-Path $addons 'BuffyProbe'
    New-Item -ItemType Directory -Path $probeTarget -Force | Out-Null
    foreach ($f in $probeFiles) { Copy-Item -LiteralPath (Join-Path $probeDir $f) -Destination (Join-Path $probeTarget $f) -Force }
    Write-Host "Deployed BuffyProbe to $probeTarget. /reload, then /fp steps bf pin." -ForegroundColor Cyan
}
