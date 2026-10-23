# Buffy agent instructions

Buffy combines Priestly, Wildly, and Magely for WoW: Forever 1.60.1, Interface 16001.
Author: Spotnick. CurseForge project: 1760483. Lua 5.1 only; Vanilla content on Retail APIs.

## Architecture

- BuffyCompat.lua is the only library bootstrap and reporter. It requires LibGroupBuffs r32.
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
pwsh tests/run.ps1 -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
pwsh Tools/package.ps1 -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
```

The initial companion worktrees are recorded in docs/IMPLEMENTATION.md. Once merged, use
the sibling checkouts at the declared pins. tests/check_package.py checks a staged directory
or zip, including dependency bytes and licenses. The normal runner syntax-checks the TOC
and runs every tests/test_*.lua. Extend strict stubs only after checking the current API dump.
For a library change, run its suite and Priestly/Wildly/Magely against the modified checkout.
Document baseline failures without changing unrelated repositories.

Use $wow-addon-review for requested WoW code reviews; post completed PR reviews on the PR
under the standing user authorization. This is implementation guidance, not a review request.

## Packaging and release

.pkgmeta embeds LibGlass r11 and an immutable LibGroupBuffs tag or full commit. A local
development commit must be published to the library repository before remote package CI can
fetch it. Switch to the released r32-or-newer tag after its in-game acceptance. Never use latest.
Include dependency licenses. Exclude tests, Tools, docs, .work, and the source PNG from packages.

Remote creation, PRs, release tags, publishing, and game-folder deployment are separate actions.
Do not deploy just to validate packaging; use a staging folder. Preserve original sibling work.
The approved plan is docs/PLAN.md. Finish the current milestone and report tests and remaining
in-game acceptance before starting another milestone.
