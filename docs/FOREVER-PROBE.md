# BuffyProbe: in-game checks

BuffyProbe (`Tools/BuffyProbe`) is a ForeverProbe module (`/fp bf`). It holds the in-game check of a
library pin as a guided procedure, so the owner follows a panel of buttons and every answer is saved.
Nothing is pasted back. The client's own measurements live in Priestly's `docs/FOREVER-PROBE.md` and in
`References/Docs/PORTING-TBC-TO-FOREVER.md`. This file records only what Buffy's own checks found.

## Running it

```powershell
pwsh Tools/deploy.ps1 -Library .work/LibGroupBuffs-r34 -LibGlass .work/LibGlass-r13 -Probe
```

Then, in game, `/reload` and `/fp steps bf pin`. `/fp bf state` and `/fp bf spells` are the two
measurements on their own. When the procedure ends, `/reload` writes the results to
`WTF\Account\<account>\SavedVariables\BuffyProbe.lua` (the log) and `ForeverProbe.lua`
(`steps.records["BuffyProbe/pin"]`, and the host's log of any `ADDON_ACTION_BLOCKED`). A session reads
those files itself and opens the screenshots with `..\ForeverProbe\Tools\screenshots.ps1 -Module BuffyProbe`.

## `pin`: Buffy on its library pin (#35)

Measured: the client build, the running LibGroupBuffs and LibGlass minors (at least `EXPECT` in the
probe: r34 and r13; a newer copy loaded by Priestly, Wildly or Magely wins through LibStub), which of
those three are loaded, and the spell report's counts (`unresolved` and `unknown` must be 0) on two
classes. Lua errors and blocked actions aren't asked: the session reads Bugsy's
`!Bugsy.lua` (per session, stacks included) and ForeverProbe's host log afterwards. Asked, with
screenshots: the window opening, moving, minimizing and restoring,
the 5 and 8 previews and both growth directions, a click casting on the member clicked, the tooltip
and timer colours, close and minimize in combat, a battleground's `?` marks (optional), and the vendor
restock and reagent footer.

Checked offline, not in game: CurseForge's own zips of v1.0.0 (file 9431326) and v1.0.1 (9431436)
pass `tests/check_package.py` (47 runtime files, library bytes at r34 and r11) and carry no
`Libs/LibGroupBuffs-1.0/docs`, `tests` or `Tools` (2026-11-18).

## `cd`: what a cooldown pane can read (#52)

The pane (#52) would list the group's Innervate and Power Infusion providers. Magely's probe
measured that another player's `UNIT_SPELLCAST_SUCCEEDED` carries a **secret** spell id (70959), so
the only source is each provider announcing its own cast by addon message. Addon messages in
combat were measured on 70790 (porting guide, PARTY and RAID), and the owner reports them working in
instances since 2026-11-04. So `cd` measures the two things left:

- **Our own instant cast in combat:** does `UNIT_SPELLCAST_SUCCEEDED`'s `spellID` stay plain? It's
  measured out of combat and then in combat. Each cast logs whether `spellID` and `castGUID` are
  secret, and the spell's name. The checks pass only on a plain id. The 70338 measurement
  (`UnitCastingInfo`) covered cast-time spells, not instants.
- **The traits tree** (`C_ClassTalents.GetActiveConfigID`, then `C_Traits` config → trees → nodes →
  entry → definition → spell): how many nodes, which have a rank, and the spell behind each, for us
  and for an inspected player (`NotifyInspect`, `INSPECT_READY`, the inspect config).
  - Power Infusion is matched by Classic's id (10060) **or by its name**, since Forever re-ids some
    spells (Mark of the Wild cast as 1328375). The ids the client gives for "Power Infusion" and
    "Innervate" (`C_Spell.GetSpellInfo(name)`) are logged too.
  - The inspect config is `Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID` if the client has it,
    otherwise -1 as on Retail. The log says which.

`/fp bf talents` runs the tree walk on its own.

## Results

### `pin` rev 1: LibGroupBuffs r34 + LibGlass r13 (#35), 2026-11-18

Client 1.60.1.70959 (enUS), Buffy `dev` from main after #43 (deployed with `.work/LibGroupBuffs-r34`
and `.work/LibGlass-r13`), account SPOTNICK3. Druid level 14 (ForeverProbe run #421), then Mage after a relog (#422). Steps 1–24
done; step 25 (`/reload` to save) was replaced by a logout, which wrote everything to disk.

| What | Result |
|---|---|
| Running copies | LibGroupBuffs minor 34, `ready` 34; LibGlass minor 13. Loaded alongside Priestly v2.1.0, Wildly v1.1.0 and Magely v1.1.0 (Druid); on the Mage, Magely was not loaded. CHECK PASS |
| Lua errors and blocked actions | None. Bugsy (`!Bugsy.lua`, SPOTNICK3) holds 0 problems in sessions 104–106, which cover both runs, with `dropped` 0. ForeverProbe's host log has no `ADDON_ACTION_BLOCKED` in #421 or #422. Bugsy's 19 `ADDON_ACTION_BLOCKED: 'Buffy' …` entries of session 103 (16:37, before this run) come from LibGroupBuffsProbe's deliberate in-combat sweep: that probe is on every stack. Step 3 asked the owner instead and got an ambiguous "No"; rev 3 drops the question, since Bugsy answers it |
| `/buffy help` and the spell report | Ran without error. Druid: 2 buffs, 3 names, 2 learned (Gift of the Wild not learned at 14), 0 unresolved, 0 unknown, 0 unreadable ranks. Mage: 3 buffs, 4 names, 3 learned, all 0. CHECK PASS on both |
| Window | Opened; moved, minimized and restored normally (yes) |
| Preview | `/buffy test 5` and `test 8` showed 5 and 8 groups (screenshot: rows, icons and timers as before, yes); `test off` returned to live data. CHECK PASS |
| Growth | Both directions work (yes). The screenshot was taken after switching back, so it shows only the default; rev 2 keeps the flipped layout up for the shot |
| Click-cast | One cast counted after a click on Buffy's window: spell 1328375, Mark of the Wild (its timer went from 43:48 at 16:53:26 to 57:11 at 16:57:37). It landed on the target clicked (yes). Its name wasn't recorded (the removed global `GetSpellInfo`, fixed in #45) |
| Tooltip and timer colours | Right (yes). No screenshot: the step relied on the owner typing `/fp shot` |
| Combat | Entered and left with the window open; close and minimize behaved as before in combat (yes); the window settled afterwards (yes, screenshot) |
| Battleground `?` marks | Skipped |
| Vendor | MERCHANT_SHOW at a reagent vendor (Horthus, Orgrimmar); restock and the reagent footer behaved as in beta1 (yes). The Druid had no Gift of the Wild, so no reagent purchase was due: this doesn't test restock buying (#10) |

The screenshots were looked at and then deleted with `screenshots.ps1 -Remove`.

**r36.** LibGroupBuffs r36 (window text in LibGlass's language font) was deployed by Priestly at
17:37 on account SPOTNICK2, and LibStub ran it for every window, Buffy's included. Bugsy (SPOTNICK2) holds
0 problems for that session. Buffy's own check of r36 is #46, still open: the minor that ran isn't
logged on Buffy's side, and the owner hasn't confirmed Buffy's window there yet.
