# In-game acceptance

## Owner feedback after development deployment

The owner reports that Buffy works well on **Priest and Mage**, and has confirmed
**Mark of the Wild works on Druid**.

This feedback follows the deployment recorded in IMPLEMENTATION.md (client 1.60.1.70532,
Buffy `dev`, LibGroupBuffs commit `13f637b68f337a3a4aac8d69c9c9c70b7ed42fd4`, LibGlass r11).
Individual checklist scenarios were not specified, so this records general successful use
on Priest and Mage and Mark of the Wild on Druid without marking every scenario below as verified.
Other Druid behavior, including Thorns modes and Gift of the Wild, was not specified.

On 2026-10-23, after LibGroupBuffs PR #69 merged and its merge commit
`b51d77573924b802b28561b028c4dc125fcdadbe` was tagged `r32`, the owner
reported that the in-game check works. No class, client build, or individual
steps were specified for this check, so the detailed scenarios below remain open.

## Detailed checklist

Not performed by offline tests. Use the exact pinned library revision. Disable the
matching original addon for the main pass.

- On Priest, Druid, and Mage, log in and verify only the matching buff rows/settings appear.
  Check an unsupported class has no buff window and `/buffy` explains why.
- Solo toggle, group join/leave, ready check, manual hide, reload, and learning a new spell
  should preserve visibility policy. Verify single-target fallback before learning group spells.
- Left/right clicks on rows and member popovers should cast the intended spells on eligible
  targets. Verify hunter/warlock pet exclusion for Fortitude, Divine Spirit, Shadow Protection,
  Mark of the Wild and Arcane Intellect (and that Forever refuses Shadow Protection on them), all five Thorns modes (Everyone includes tracked pets), role changes, and Mage
  Amplify/Dampen detection independently. Verify instance selections and a non-English locale.
- During combat, request show/hide, resize, reset, and minimize/restore. Confirm no blocked
  action/taint errors and that deferred changes apply when combat ends. Check aura unknown states.
- Inspect row, popover, header, reagent counter, tooltip, scale, and logo rendering. Drag the
  window, lock it, reset it, and check popover placement near screen edges.
- Change class settings and position; exit the entire client and restart. Verify settings
  persist. Check another character of the same class shares buff settings but has separate
  position/visibility, and a different class has its own profile. `/reload` alone is insufficient.

## At an Interface bump

A new client build with the same Interface (the 4th value of `GetBuildInfo()`) is not a re-check:
it is diffed centrally, and only a name the diff removed or changed comes to Buffy, as its own
issue. A new Interface (a new `## Interface:` for `Buffy.toc`) is the full check, even when the diff
is empty:

- Bump `## Interface:` in `Buffy.toc` and `build=` in `tests/kit.pin`, and run the tests.
- Run `/fp steps bf pin` ([FOREVER-PROBE.md](FOREVER-PROBE.md)) on the pinned libraries, with
  nothing skipped this time:
  - both growth directions;
  - close and minimize in combat;
  - a vendor visit where a restock purchase is due;
  - a second class;
  - a battleground's `?` marks.
- Read Bugsy (`!Bugsy.lua`) for any error from `AddOns/Buffy/`, and record the result here with
  the client build it ran on.
- Learned durations are relearned once on the new Interface (`BuffyConfig.lua`); that is expected.

## Pending checks for Buffy issues #5-#11

These changes were tested offline against local LibGroupBuffs commit
`dcf34b7c7ae8228dbfb6d096e09d0465252f7397` (minor 33), LibGroupBuffs #70's head,
merged into the library's `main` as `c7e2137` and tagged `r33` on 2026-10-24.
v0.1.1-alpha1 and -alpha2 pinned the commit; from alpha3 Buffy pins `tag: r33`.
Record the client build, Buffy version, vendor and item where relevant, before/after bag
counts and money, and the result for each check.

- Priest: enable the battleground Shadow override under each visibility mode. Confirm the
  row appears in a battleground, disappears according to the normal mode outside it, and
  does not change arena behavior.
- All three classes: grow the window down and up as rows appear or disappear. Verify old
  saved positions, dragging, reset, scale, minimize, combat deferral, and a full restart.
- All three classes: inspect `/buffy test 5`, `test 8`, and `test off` while solo and after
  the window was hidden. Try row and popover clicks; they must never cast in preview. Enter
  combat, request `test off`, and confirm the live roster returns afterward.
- All three classes: hide/show the reagent footer, including its divider and height. Test
  a combat-time change and a full restart; verify class settings stay separate.
- Priest: with auto-buy off, visit a candle vendor and confirm no purchase. With it on,
  check rank 1 Fortitude (Holy Candle), Shadow Prayer alongside rank 1 Fortitude (both),
  and rank 2 Fortitude or Spirit (Sacred Candle). Check target, stock, money, bag space,
  repeated visits, and the inventory-based purchase message. Confirm other vendors and
  extended-cost items are ignored.
- Druid: with auto-buy off and on, check Gift rank 1 buys Wild Berries and rank 2 buys
  Wild Thornroot. Confirm no purchase for an unlearned/unknown-rank Gift or disabled Mark.
- Mage: with auto-buy off and on, confirm Arcane Intellect alone buys no Powder; learned
  Arcane Brilliance buys it only while Intellect tracking is enabled.
- For Druid and Mage purchases, also check the target, limited stock, money, bag space,
  repeated visits, wrong vendors, extended costs, and inventory-based messages.
- All three classes: restock with a shortfall larger than one stack (e.g. the default
  target of 80 from an empty bag). Buffy asks for the whole shortfall in one
  `BuyMerchantItem` call and does not read `GetMerchantItemMaxStack`, while Blizzard's
  merchant UI never buys more than that limit at once. Record whether one visit buys the
  full amount, one stack, or nothing.

The owner chose an alpha release before these in-game checks because the beta is closing.
The v0.1.1 alphas ship that library revision without these checks. Do not mark these
scenarios as verified. `r33` was tagged before them to fix CurseForge packaging.

On 2026-11-03, the day before game access returns, the owner chose to ship the same code and
pins as v1.0.0-beta1, still without these checks. The plan then was for the stable v1.0.0
(formerly the planned v0.1.1) to wait for this checklist, run against the library pin it ships with.

On 2026-11-04, the day game access returned, the owner chose to ship the stable v1.0.0 before
these checks, on LibGroupBuffs `tag: r34` (`1ede1c1`, minor 34) and LibGlass r11. They now
run after the release, against r34, together with the r34 check in Buffy #35. Do not mark them
verified until they are run.

On 2026-11-18, after v1.0.1, main moved to LibGlass r13 (`5b2c9ab`). The checks that run from
then on run against r34 and r13, which is what the next release ships.

## LibGroupBuffs r34 on LibGlass r13 (#35), 2026-11-18

Run as BuffyProbe's guided procedure (`/fp steps bf pin`). The step-by-step results are in
[FOREVER-PROBE.md](FOREVER-PROBE.md). Client 1.60.1.70959, enUS, on a Druid then a Mage. Every measured check passed:
- the running minors (34 ready, LibGlass 13);
- the spell report on both classes, with 0 unresolved and 0 unknown names;
- preview on and off;
- a click-cast that landed on its target.

The owner confirmed every visual and behavioural step: the window, the 5 and 8 previews, both growth directions, the
tooltip and timer colours, close and minimize in combat, and a vendor visit. Bugsy logged no Lua
error or blocked action. The battleground step was skipped.

This covers some of the pending checks above only in part. The previews and growth were checked
solo, on one class, without a full restart. The vendor visit was on a Druid without Gift of the
Wild, so no restock purchase was due. Those scenarios stay open.

## LibGroupBuffs r36 on LibGlass r13, build 71037 (#58), 2026-11-21

A partial `/fp steps bf pin` on client 1.60.1.71037, enUS, on a Mage. The results are in
[FOREVER-PROBE.md](FOREVER-PROBE.md) (rev 3). Every measured check that ran passed: the running minors
(36 ready, LibGlass 13), the spell report with 0 unresolved and 0 unknown, and preview on and off. A
click-cast (Arcane Intellect) landed on its target. The owner confirmed the window, the 5 and 8 previews and
the tooltip colours. Bugsy logged no Lua error or blocked action.

Growth, combat, the vendor and a second class were skipped on this build; they passed on 70959
above. The battleground `?` marks were skipped on both builds and are still to check.

## Refusal memory, LibGroupBuffs 3fab1f9 = r39 (#68), 2026-11-25

The owner's check of Buffy #68 (b96495e, library `3fab1f9`, later tagged r39, LibGlass r13), on a
Priest, in a group with a priest and a mage. Fortitude on the priest was refused with "A more
powerful spell is already active", and the next click skipped them and buffed the mage.
Before that, the mage already had Fortitude (the owner: "the higher fortitude on my mage"), and
with nobody else needing it, a top-up click on the mage was refused too. The client's refusal names
neither the blocking aura nor its strength, so Buffy can't avoid that first cast. A separate library
run, #522, showed the row arms nothing after such a bounce. Nothing else misbehaved.
Bugsy logged no Buffy or LibGroupBuffs error. Only the single-target click was checked. Prayer of
Fortitude on a refused member, and an action-bar or macro bounce teaching the window, are
unmeasured in Buffy. The client build wasn't recorded.

## No build check, LibGroupBuffs 52b6f9e = r40 (#78), 2026-11-28

The r40 pilot (LibGroupBuffs#101): Buffy main 1422d2e with library `52b6f9e`, later tagged r40, and
LibGlass r13, on client 1.60.1.71139. The deployed library declared MINOR 40. Priestly, Magely and
Wildly still embedded r39, but LibStub keeps the highest minor. The owner did a full exit, a real
login and a `/reload` in both clients, and saw no "tested on game build" line ("it works").
Bugsy, read from both accounts after the reloads, had no problem in either session and none ever
from `AddOns/Buffy/`. Nothing else was checked on r40. #78 then dropped `measuredOnBuild` and the
`newBuild` filter, which r40 ignores and never sends.

After #78 (and #80), Buffy main f4f843f with r40 and LibGlass r13 was deployed with `-Probe` on the
same client, the first real deploy through ForeverProbe's `-Module` (#77). After a `/reload`
(account SPOTNICK2), BuffyProbe reported `deployed f4f843f` and `/fp bf` listed its commands.
Bugsy's session had no problem, and none from `AddOns/Buffy/` or `AddOns/BuffyProbe/`. This is
the v1.0.5 code. Durations kept across a client build (#72) are covered by tests only: the next
build is the first chance to see it.

## GlassUI integration

GlassUI PR #160, the hub roster entry, merged on 2026-10-24 UTC. GlassUI itself is not
released yet (private repository, no tags), so players get the hub entry only once it ships.
These checks remain open and do not block a Buffy release:

- Test GlassUI absent, follow on/off, Pearl, clear/smoked/class tint, and gold/ice accent.
  Change each and reload. Confirm the hub shows pending reload and the effective appearance.
  Local opacity should be disabled while following and restored when follow is off.
- Enable the matching original addon once. Confirm Buffy can follow GlassUI while the original
  keeps its own material and opacity, regardless of library load order.

Record client build, addon/library revision, class, steps, and results before claiming runtime
acceptance or releasing. The newest API dump inspected during implementation was 1.60.1.70532.
