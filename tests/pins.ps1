<#
    pins.ps1 - Is a library checkout at the ref .pkgmeta pins for it?

    Dot-sourced by tests/run.ps1 and Tools/deploy.ps1, which used to carry a
    copy each. The pin is read BY PATH through tests/pkgmeta.lua, the one
    reader of .pkgmeta's externals: with two externals, the first `tag:` in
    the file is LibGlass's.

        . (Join-Path $RepoRoot "tests\pins.ps1")
        $s = Get-PinState -Lua $Lua -RepoRoot $RepoRoot -Path "Libs/LibGlass-1.0" -Root $LibGlass
        # $s.Pin       "<kind> <ref>", or $null when .pkgmeta pins nothing there
        # $s.Ref       the ref alone
        # $s.Revision  `git describe` of the checkout, "plain copy, MINOR N", or why there is none
        # $s.AtPin     HEAD is the pinned commit and nothing is uncommitted;
        #              for a plain copy, the pin is tag rN and the copy's MINOR is N
        # $s.Dirty     there are uncommitted changes

    A plain copy is a folder that is not its own checkout: a downloaded zip, or
    a copy inside another repository. Git would walk up from a copy inside
    another repository and describe THAT one, so a copy is recognised first
    (`git rev-parse --show-prefix` is empty only at a checkout's top), and
    its MINOR is read from the line that gives LibStub its version. A folder
    with its own .git that git can't read is a checkout, left unverified. A MINOR
    says which release the copy claims to be, not that its bytes are that
    release.

    Informational only. It never throws and leaves $LASTEXITCODE at 0: no git,
    or a checkout that is not one (a downloaded zip), must not stop a test run
    or a deploy for a line that only prints.
#>

# A plain copy's MINOR, from `local MAJOR, MINOR = "<major>", N` or
# `LibStub:NewLibrary("<major>", N)` in a .lua file at its top. The major is
# the last part of the .pkgmeta path (Libs/LibGlass-1.0). $null when none says.
function Get-PlainCopyMinor {
    param([string]$Root, [string]$Major)
    $pattern = '(?:MINOR\s*=|NewLibrary\s*\()\s*"' + [regex]::Escape($Major) + '"\s*,\s*(\d+)'
    foreach ($f in @(Get-ChildItem -LiteralPath $Root -Filter *.lua -File -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $m = Select-String -LiteralPath $f.FullName -Pattern $pattern -List
        if ($m) { return [int]$m.Matches[0].Groups[1].Value }
    }
    return $null
}

function Get-PinState {
    param(
        [Parameter(Mandatory)][string]$Lua,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )
    $state = [pscustomobject]@{ Pin = $null; Ref = $null; Revision = "not a git checkout"; AtPin = $false; Dirty = $false }

    Push-Location $RepoRoot
    try {
        $pin = & $Lua (Join-Path $RepoRoot "tests\pkgmeta.lua") $Path 2>$null
        if ($LASTEXITCODE -eq 0 -and $pin) {
            $state.Pin = "$pin"
            $state.Ref = ("$pin" -split ' ', 2)[1]
        }
    } catch { } finally { Pop-Location }

    $plainCopy = {
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) { $state.Revision = "no folder"; return }
        $minor = Get-PlainCopyMinor -Root $Root -Major (Split-Path -Leaf $Path)
        if ($null -eq $minor) { $state.Revision = "plain copy, no MINOR found"; return }
        $state.Revision = "plain copy, MINOR $minor"
        $state.AtPin = [bool]($state.Pin -and ("$($state.Pin)" -split ' ', 2)[0] -eq "tag" -and $state.Ref -ceq "r$minor")
    }

    try {
        $prefix = git -C $Root rev-parse --show-prefix 2>$null
        if ($LASTEXITCODE -ne 0 -or "$prefix".Trim()) {
            # Not a checkout git can read at its top. A folder with its own .git
            # (a directory, or a worktree's file) is still a checkout - git may
            # refuse it (safe.directory's ownership check, a moved worktree) or
            # skip a broken one and describe the parent - so its pin stays
            # unverified, never matched by MINOR. Only a folder with no .git is
            # a plain copy.
            if (Test-Path -LiteralPath (Join-Path $Root ".git")) {
                $state.Revision = "a checkout git could not read"
            } else { . $plainCopy }
            $global:LASTEXITCODE = 0
            return $state
        }
        $r = git -C $Root describe --tags --always --dirty 2>$null
        if ($LASTEXITCODE -eq 0 -and $r) {
            $state.Revision = "$r"
            $state.Dirty = [bool](git -C $Root status --porcelain 2>$null)
            if ($state.Ref) {
                $want = git -C $Root rev-parse --verify --quiet "$($state.Ref)^{commit}" 2>$null
                $head = git -C $Root rev-parse HEAD 2>$null
                $state.AtPin = [bool]($want -and $want -eq $head -and -not $state.Dirty)
            }
        }
    } catch { $state.Revision = "git not available" }

    $global:LASTEXITCODE = 0
    return $state
}
