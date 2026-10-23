# Stage a development package from the same TOC/XML manifests the tests load.
param(
    [string]$Destination = '', [string]$Library = '', [string]$LibGlass = '',
    [string]$Lua = 'C:\Program Files (x86)\Lua\5.1\lua.exe'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Destination) { $Destination = Join-Path $repo '.work\package' }
if (-not $Library) { $Library = Join-Path (Split-Path -Parent $repo) 'LibGroupBuffs' }
if (-not $LibGlass) { $LibGlass = if ($env:LIBGLASS) { $env:LIBGLASS } else { Join-Path (Split-Path -Parent $repo) 'LibGlass' } }
$Library = (Resolve-Path -LiteralPath $Library).Path
$LibGlass = (Resolve-Path -LiteralPath $LibGlass).Path
$destRoot = [IO.Path]::GetFullPath($Destination)
$addon = [IO.Path]::GetFullPath((Join-Path $destRoot 'Buffy'))
if ((Split-Path -Parent $addon) -ne $destRoot.TrimEnd('\', '/')) { throw 'Invalid package destination.' }
if (Test-Path -LiteralPath $addon) {
    throw "Package destination already exists: $addon. Choose a new -Destination or remove that staging folder."
}
$toc = Get-Content -LiteralPath (Join-Path $repo 'Buffy.toc')
$own = @('Buffy.toc', 'Media/Logo.tga', 'LICENSE', 'THIRD_PARTY_NOTICES.md') + @($toc |
    ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[^#].*\.lua$' })
$libFiles = & $Lua (Join-Path $repo 'tests/libfiles.lua') $Library ship $LibGlass
if ($LASTEXITCODE -ne 0) { throw 'LibGroupBuffs manifest failed.' }
$glassFiles = & $Lua (Join-Path $repo 'tests/libfiles.lua') --glass $LibGlass ship
if ($LASTEXITCODE -ne 0) { throw 'LibGlass manifest failed.' }
$copies = @()
foreach ($file in $own) { $copies += @{ source = (Join-Path $repo $file); relative = $file } }
foreach ($file in $libFiles) { $copies += @{ source = (Join-Path $Library $file); relative = "Libs/LibGroupBuffs-1.0/$file" } }
foreach ($file in $glassFiles) { $copies += @{ source = (Join-Path $LibGlass $file); relative = "Libs/LibGlass-1.0/$file" } }
foreach ($item in $copies) {
    if (-not (Test-Path -LiteralPath $item.source -PathType Leaf)) { throw "Missing package file: $($item.source)" }
}
Push-Location $repo
try {
    . (Join-Path $repo 'tests/pins.ps1')
    foreach ($dep in @(@('LibGroupBuffs-1.0', $Library), @('LibGlass-1.0', $LibGlass))) {
        $pin = Get-PinState -Lua $Lua -RepoRoot $repo -Path "Libs/$($dep[0])" -Root $dep[1]
        Write-Host "$($dep[0]): $($pin.Revision), pin $($pin.Pin), matches: $($pin.AtPin)"
    }
} finally { Pop-Location }
foreach ($item in $copies) {
    $target = Join-Path $addon $item.relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $item.source -Destination $target
}
$tocPath = Join-Path $addon 'Buffy.toc'
(Get-Content -LiteralPath $tocPath -Raw).Replace('@project-version@', 'dev') |
    Set-Content -LiteralPath $tocPath -Encoding utf8
Write-Host "Staged $($copies.Count) runtime files in $addon"
