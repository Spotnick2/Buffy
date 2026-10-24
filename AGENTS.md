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

The companion changes are merged (LibGroupBuffs #69 and #70, GlassUI #160). The .work
worktrees above sit at the declared pins; any checkout at those pins will do, and the runner
reports whether each library matches its pin. tests/check_package.py checks a staged directory
or zip, including dependency bytes and licenses. The normal runner syntax-checks the TOC
and runs every tests/test_*.lua. Extend strict stubs only after checking the current API dump.
For a library change, run its suite and Priestly/Wildly/Magely against the modified checkout.
Document baseline failures without changing unrelated repositories.

Use $wow-addon-review for requested WoW code reviews; post completed PR reviews on the PR
under the standing user authorization. This is implementation guidance, not a review request.
For a separate architecture or risk consult, the `codex-consult` skill
(`.claude/skills/codex-consult`) can run Codex headlessly. `$wow-addon-review` remains
authoritative for the WoW code-review method and verdict.

## Packaging and release

.pkgmeta embeds LibGlass r11 and LibGroupBuffs r33 (dcf34b7, minor 33). Pin tags only:
v0.1.1-alpha1 and -alpha2 pinned the same library commit by `commit:`, and CurseForge's tag
webhook built no file for either, so a library pilot gets a tag first. v0.1.0 shipped on r32.
Never use latest.
Include dependency licenses. Exclude tests, Tools, docs, .work, and the source PNG from packages.

Releases follow ../References/Docs/RELEASING.md. The repository is public and CurseForge project
1760483 has a tag webhook: pushing a tag makes CurseForge build its own file from .pkgmeta (the
tag name decides release/beta/alpha), while the tag's CI run publishes the checked ZIP and
release.json on GitHub and uploads the same ZIP to Wago project QNl4o8Ne
(https://addons.wago.io/addons/QNl4o8Ne; WAGO_API_TOKEN secret). Check CurseForge's ZIP with tests/check_package.py afterwards; CI proves
only the BigWigs build. README.curseforge.md is the CurseForge description and stays untracked.

Remote creation, PRs, release tags, publishing, and game-folder deployment are separate actions.
Do not deploy just to validate packaging; use a staging folder. Preserve original sibling work.
Tools/deploy.ps1 targets the live `_forever_` client; pass `-AddOnsPath` for `_classic_beta_`.
The approved plan is docs/PLAN.md. Finish the current milestone and report tests and remaining
in-game acceptance before starting another milestone.
