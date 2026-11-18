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
classes. Asked, with screenshots: no Lua error, the window opening, moving, minimizing and restoring,
the 5 and 8 previews and both growth directions, a click casting on the member clicked, the tooltip
and timer colours, close and minimize in combat, a battleground's `?` marks (optional), and the vendor
restock and reagent footer.

Checked offline, not in game: CurseForge's own zips of v1.0.0 (file 9431326) and v1.0.1 (9431436)
pass `tests/check_package.py` (47 runtime files, library bytes at r34 and r11) and carry no
`Libs/LibGroupBuffs-1.0/docs`, `tests` or `Tools` (2026-11-18).

## Results

Not run yet.
