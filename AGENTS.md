# Buffy agent instructions

Buffy combines Priestly, Wildly, and Magely for WoW: Forever 1.60.1, Interface 16001.
Author: Spotnick. CurseForge project: 1760483. Lua 5.1 only; Vanilla content on Retail APIs.

## Architecture

- BuffyCompat.lua is the only library bootstrap and reporter. It requires LibGroupBuffs minor 33 (`NEEDS_MINOR`).
- Classes/Priest.lua, Druid.lua, Mage.lua contain definitions, defaults, instance data,
  targeting rules, spec appearance, and reagent data adapted from the original addons.
- Buffy.lua selects one class at ADDON_LOADED, creates exactly one engine/UI/visibility
  controller for supported classes, and owns the event dispatcher and /buffy command.
- BuffyConfig.lua owns every saved write. BuffyAccountDB.classes stores profiles by class
  token, including learned durations. BuffyDB stores per-character position and visibility.
  Do not import or write PriestlyDB, WildlyDB, or MagelyDB.
- BuffyOptions.lua builds one settings category for the active class, with common controls.
- BuffyAppearance.lua asks GlassUI.Suite API 1 after saved variables load, before creating
  material. Theme/look changes require reload. Never mutate LibGroupBuffs' shared material.
- Buff engine, aura handling, secure click mappings, UI, and visibility policy belong in
  LibGroupBuffs. Do not copy its implementation into Buffy.

## Client evidence and safety

Read ../References/Docs/PORTING-TBC-TO-FOREVER.md before touching an unfamiliar API. Use the
newest ../References/Forever/api/forever-api-<version>.<build>.md (70532 at initialization).
The dump proves API presence, not rendering, taint safety, or persistence. Check Blizzard's
shipped code in ../wow-ui-source and measurements in ../Priestly/docs/FOREVER-PROBE.md.
Owner acceptance covers Priest, Mage, and Druid Mark of the Wild; see docs/ACCEPTANCE.md.
Do not advance specific measured build claims from offline tests or general acceptance feedback.

All moved APIs go through Buffy.API at call time. Never capture library implementation
functions: LibStub upgrades in place. Aura secrecy can throw on comparisons; keep raw aura
handling in the library. Never move, hide, resize, create, or rewrite attributes on secure
frames in combat. Let the library defer the operation. Register events through Buffy.RegisterEvents.

## Validation

Libraries are sibling checkouts or explicit paths, never committed in Libs/.

```powershell
pwsh tests/run.ps1 -Library .work/LibGroupBuffs-r39 -LibGlass .work/LibGlass-r13
pwsh Tools/package.ps1 -Library .work/LibGroupBuffs-r39 -LibGlass .work/LibGlass-r13
```

The companion changes are merged (LibGroupBuffs #69 and #70, GlassUI #160). The .work
worktrees above sit at the declared pins; any checkout at those pins will do, and the runner
reports whether each library matches its pin. tests/check_package.py checks a staged directory
or zip, including dependency bytes and licenses. The normal runner syntax-checks the TOC
and runs every tests/test_*.lua. Extend strict stubs only after checking the current API dump.

The test scaffolding is WowTestKit (`C:\Projects\WoW\WowTestKit`; its README is the reference),
at the commit and client build `tests\kit.pin` names. `tests\run.ps1` puts that commit in
`%LOCALAPPDATA%\WowTestKit\<sha>` and hands off to the kit's runner; CI fetches it with
`tests\fetch_kit.sh`. `tests\kit.lua`, `kit.ps1` and `fetch_kit.sh` are the kit's bootstrap
copies: never edit them here. Buffy has no stub of its own: the mock is LibGroupBuffs' shared
`tests/wow_stubs.lua` (r35 and later build it on the kit, from Buffy's `kit.pin`), and
`tests/harness.lua` adds Buffy's globals. A kit need is an issue on WowTestKit, worked around in
the harness with a `-- WowTestKit #N:` comment meanwhile. `tests\run.ps1 -KitDev` runs against the
`..\WowTestKit` working copy instead of the pin. `tests/test_methods.lua` checks every widget method
Buffy's frames call against the pinned build (`Kit.checkMethods`).
For a library change, run its suite and Priestly/Wildly/Magely against the modified checkout.
Document baseline failures without changing unrelated repositories.

Use $wow-addon-review for requested WoW code reviews; post completed PR reviews on the PR
under the standing user authorization. This is implementation guidance, not a review request.
For a separate architecture or risk consult, the `codex-consult` skill
(`.claude/skills/codex-consult`) can run Codex headlessly. `$wow-addon-review` remains
authoritative for the WoW code-review method and verdict.

## Packaging and release

.pkgmeta embeds LibGlass r13 (`5b2c9ab`) and LibGroupBuffs r39 (3fab1f9, minor 39). Pin tags only:
v0.1.1-alpha1 and -alpha2 pinned the same library commit by `commit:`, and CurseForge's tag
webhook built no file for either, so a library pilot gets a tag first. v0.1.0 shipped on r32,
v1.0.0-beta1 on r33, v1.0.0 and v1.0.1 on r34. v1.0.0 and v1.0.1 shipped LibGlass r11; main pins
LibGlass r13 since 2026-11-18, and LibGroupBuffs r39 (refusal memory, #97) since #68, after its
in-game pilot on that commit (r37 and r38 were never tagged).
Never use latest.
Include dependency licenses. Exclude tests, Tools, docs, .work, and the source PNG from packages.

Releases follow ../References/Docs/RELEASING.md. The repository is public and CurseForge project
1760483 has a tag webhook: pushing a tag makes CurseForge build its own file from .pkgmeta (the
tag name decides release/beta/alpha), while the tag's CI run publishes the checked ZIP and
release.json on GitHub and uploads the same ZIP to Wago project QNl4o8Ne
(https://addons.wago.io/addons/QNl4o8Ne; WAGO_API_TOKEN secret). Check CurseForge's ZIP with tests/check_package.py afterwards; CI proves
only the BigWigs build. README.curseforge.md is the CurseForge description and stays untracked.
A release tag (`vX.Y.Z`, not an alpha or beta) updates README.md and README.curseforge.md in
its prep PR so both describe that release (RELEASING.md §3); the PR says whether
README.curseforge.md changed, since the owner pastes it into CurseForge and Wago afterwards.

Remote creation, PRs, release tags, publishing, and game-folder deployment are separate actions.
Do not deploy just to validate packaging; use a staging folder. Preserve original sibling work.
Tools/deploy.ps1 targets the live `_forever_` client; pass `-AddOnsPath` for `_classic_beta_`.
`-Probe` also deploys ForeverProbe and BuffyProbe (`/fp bf`), whose `/fp steps bf pin` is the
in-game check of a library pin; see docs/FOREVER-PROBE.md. Its test (`tests/test_probe.lua`) runs
locally only, as ForeverProbe is private: CI sets `FOREVERPROBE_OPTIONAL=1`.
The approved plan is docs/PLAN.md. Finish the current milestone and report tests and remaining
in-game acceptance before starting another milestone.
