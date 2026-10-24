# Initial implementation status

The approved working-addon milestone is implemented. The owner reports successful
Priest and Mage testing and confirms Mark of the Wild works on Druid;
see [ACCEPTANCE.md](ACCEPTANCE.md). The approved plan is preserved in [PLAN.md](PLAN.md).

## Current state (2026-10-24)

- Buffy: v0.1.0 is released on GitHub and CurseForge. v0.1.1-alpha3 (`tag: r33`) is on
  GitHub, Wago and CurseForge. alpha1 and alpha2 pinned the library by commit, and CurseForge
  built neither ([RELEASE-v0.1.1-alpha1.md](RELEASE-v0.1.1-alpha1.md), Outcome).
- LibGroupBuffs: #69 merged and tagged `r32` (`b51d775`); #70 merged as `c7e2137`; its head
  `dcf34b7` (minor 33) tagged `r33` on 2026-10-24.
- GlassUI: #160 (Buffy as a dynamic hub member) merged on 2026-10-24 UTC. GlassUI is not
  released yet (private repository, no tags).
- `.work/LibGroupBuffs` (at `dcf34b7`) and `.work/LibGlass-r11` are still the pinned checkouts
  the validation commands use. The other `.work` worktrees and staging folders are history.

The rest of this document records the initial implementation as delivered.

## Repository state at the initial implementation (2026-10-22)

- Buffy: `feat/initial-addon`, initial implementation prepared for PR review.
- LibGroupBuffs: isolated worktree at `.work/LibGroupBuffs`, branch `feat/buffy-appearance`.
  Development commit `13f637b68f337a3a4aac8d69c9c9c70b7ed42fd4`, based on upstream r31
  (`d1610d1`). Declares minor 32, adds optional per-window `glass` and `bodyStyle`, and
  freezes the actual r31 source for upgrade tests. Buffy pins this exact commit.
- GlassUI: isolated worktree at `.work/GlassUI`, branch `feat/buffy-member`, rebased onto
  upstream main (`c5b94d4`). Changes: one dynamic roster member in Suite.lua and tests/test_buffy.lua.
- LibGlass: exact r11 checkout at `.work/LibGlass-r11`; no library changes.
- Unchanged r31 baseline: `.work/LibGroupBuffs-r31`, used to distinguish old test failures.

Original sibling working directories and existing edits were preserved. These worktrees belong
to the sibling Git repositories; do not discard `.work` before delivering the companion changes.
The LibGroupBuffs companion branch is published, so remote CI can fetch Buffy's exact pin.
Companion PRs: [LibGroupBuffs #69](https://github.com/Spotnick2/LibGroupBuffs/pull/69) and
[GlassUI #160](https://github.com/Spotnick2/GlassUI/pull/160).
No release tag was created. After library in-game validation,
merge/release it through its normal workflow and replace the development pin with its release tag.

## Implemented behavior

- Shared bootstrap/configuration/options/event/command layers with separate class definitions.
- Class-shared settings and learned durations; per-character position and visibility.
- Priest, Druid, and Mage targeting, spells, reagents, instance defaults, and spec icons.
- Common scale, opacity, lock, solo, pet, and popover controls; `/buffy` diagnostics.
- Optional defensive GlassUI API 1 integration, effective tint/accent reporting, reload semantics,
  masked body backing, opacity suspension while following, and Clean fallback.
- Original source PNG plus a 256×256 game TGA; CurseForge metadata, licensing, package checks,
  local staging/deployment tooling, and GitHub dry-run packaging workflow.

## Validation

- Buffy: Lua 5.1 syntax and 165 assertions across host, config, classes, appearance, and manifest tests.
- LibGroupBuffs: complete suite passed, including material isolation and real r31/synthetic newer
  version upgrade coverage. New material test rejects a mutation that ignores the host material.
- Priestly: complete suite passed against the new library.
- GlassUI: complete suite passed, including its local ForeverProbe tests and Buffy integration.
  The Buffy test rejects removal of the new roster entry.
- Wildly: 2 pre-existing failing files (one assertion each): test_config_seam expects client build
  70205 while r31's shared stub is 70338; test_manifest lacks the library Tools exclusion.
- Magely: 2 pre-existing failing files (4 assertions total): test_stub expects build/date 70205;
  test_manifest has the same missing Tools exclusion. Both suites reproduce the identical
  failures against unchanged r31. Their other tests pass. No unrelated fixes were applied.
- Initial local package: 46 files. The first hosted package check exposed a missing
  LibGroupBuffs LICENSE in the local shipping manifest. The manifest now requires the license,
  bringing local staging and the hosted package to 47 files, with exact dependency byte checks.
  The original development artifact and deployment predate this packaging correction.

Representative commands (from Buffy unless noted):

```powershell
pwsh tests/run.ps1 -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
$env:LIBGLASS = "$PWD/.work/LibGlass-r11"
pwsh .work/LibGroupBuffs/tests/run.ps1
pwsh ../Priestly/tests/run.ps1 -Library "$PWD/.work/LibGroupBuffs"
pwsh ../Wildly/tests/run.ps1 -Library "$PWD/.work/LibGroupBuffs"
pwsh ../Magely/tests/run.ps1 -Library "$PWD/.work/LibGroupBuffs"
$env:FOREVERPROBE = 'C:/Projects/WoW/ForeverProbe'
pwsh .work/GlassUI/tests/run.ps1
pwsh Tools/package.ps1 -Destination .work/package -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
$env:LIBGROUPBUFFS = "$PWD/.work/LibGroupBuffs"
python tests/check_package.py .work/package
```

Logs and staging files are under `.work`. Use a fresh `-Destination` to build again.
The sandbox command runner failed with `setup refresh had errors`; execution used the approved
external runner. Git checks on Buffy required a command-scoped safe.directory exception because
the empty repository was originally initialized by the sandbox account.

## Development deployment — 2026-10-22

Deployed at the user's request to
`C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns` for client
1.60.1.70532:

- `Buffy/`: all 46 runtime files, version `dev`, embedding LibGroupBuffs minor 32 at the
  pinned development commit and LibGlass r11.
- `GlassUI/Suite.lua`: the Buffy dynamic roster entry. The installed file matched the tested
  base exactly before that addition, and GlassUI's installed LibGlass already matched r11.
  Only this companion file was installed; the worktree's unrelated Trade skin was not deployed.

Ran `Tools/deploy.ps1` with explicit `-Library .work/LibGroupBuffs` and
`-LibGlass .work/LibGlass-r11`, then copied the tested GlassUI Suite.lua. Buffy passed all
165 assertions and the GlassUI companion passed its five checks immediately before deployment.
All installed Buffy files and Suite.lua matched their sources by SHA-256; the deployment
stage also passed the exact package manifest and byte checks.

The prior GlassUI Suite.lua is backed up in
`.work/deployment-backup-20261022-224217/GlassUI-Suite.lua`.
Details are in `.work/deployment-receipt.json`. SavedVariables and original class addon files
were not changed. The game was running; the player must reload to load the new code.

## Next step

The owner reports that Buffy works well on Priest and Mage and confirms Mark of the Wild
works on Druid. Individual scenarios, including full-restart persistence,
were not specified in that feedback; the detailed checklist remains available in ACCEPTANCE.md.
The requested PRs cover Buffy and its LibGroupBuffs and GlassUI companions. Merges, release tags,
and release publishing remain separate actions. No legacy settings migration or additional classes were included,
as specified by the plan.
