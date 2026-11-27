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

# With -Probe, ForeverProbe's own deploy (-Module, ForeverProbe#47) installs the host and BuffyProbe.
# It checks the module first (the TOC's ForeverProbe dependency, every listed file, luac -p) and
# copies nothing if one fails, then stamps the copy's TOC with the commit, lints its globals and
# removes files the module no longer lists. It runs after Buffy's package is built and before Buffy
# is copied, so a refused probe leaves the installed Buffy untouched.
$probeDir = Join-Path $PSScriptRoot 'BuffyProbe'
$foreverProbe = if ($env:FOREVERPROBE) { $env:FOREVERPROBE } else { Join-Path (Split-Path -Parent $repo) 'ForeverProbe' }
$fpDeploy = Join-Path $foreverProbe 'Tools\deploy.ps1'
if ($Probe) {
    if (-not (Test-Path -LiteralPath $fpDeploy)) {
        throw "ForeverProbe checkout not found at $foreverProbe (or set `$env:FOREVERPROBE)"
    }
    # A checkout from before ForeverProbe#47 has no -Module: it would deploy only the host and exit 0.
    if (-not (Get-Command -Name $fpDeploy -CommandType ExternalScript).Parameters.ContainsKey('Module')) {
        throw "ForeverProbe at $foreverProbe has no deploy.ps1 -Module (ForeverProbe#47): update it to its main, then deploy again"
    }
}

$stage = Join-Path $repo ('.work\deploy-' + [guid]::NewGuid().ToString('N'))
& (Join-Path $PSScriptRoot 'package.ps1') -Destination $stage -Library $Library -LibGlass $LibGlass -Lua $Lua
if ($LASTEXITCODE -ne 0) { throw 'Package build failed; deployment stopped.' }
$target = [IO.Path]::GetFullPath((Join-Path $addons 'Buffy'))
if ((Split-Path -Parent $target) -ne $addons.TrimEnd('\', '/')) { throw 'Invalid addon target.' }

if ($Probe) {
    & pwsh -NoProfile -File $fpDeploy -AddOnsPath $addons -Module $probeDir -Lua $Lua
    if ($LASTEXITCODE -ne 0) { throw 'ForeverProbe deploy -Module refused; nothing was copied, Buffy included' }
}

New-Item -ItemType Directory -Path $target -Force | Out-Null
# Only Buffy-owned files are copied. No sibling addon or SavedVariables file is touched.
Copy-Item -Path (Join-Path $stage 'Buffy\*') -Destination $target -Recurse -Force
Write-Host "Deployed Buffy to $target"
if ($Probe) {
    Write-Host "Deployed BuffyProbe to $(Join-Path $addons 'BuffyProbe'). /reload, then /fp steps bf pin." -ForegroundColor Cyan
}
