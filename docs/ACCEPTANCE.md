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
  targets. Verify pet exclusion for Fortitude, all five Thorns modes, role changes, and Mage
  Amplify/Dampen detection independently. Verify instance selections and a non-English locale.
- During combat, request show/hide, resize, reset, and minimize/restore. Confirm no blocked
  action/taint errors and that deferred changes apply when combat ends. Check aura unknown states.
- Inspect row, popover, header, reagent counter, tooltip, scale, and logo rendering. Drag the
  window, lock it, reset it, and check popover placement near screen edges.
- Change class settings and position; exit the entire client and restart. Verify settings
  persist. Check another character of the same class shares buff settings but has separate
  position/visibility, and a different class has its own profile. `/reload` alone is insufficient.

## Pending checks for Buffy issues #5-#11

These changes were tested offline against local LibGroupBuffs commit
`dcf34b7c7ae8228dbfb6d096e09d0465252f7397` (minor 33). The commit is pinned in
Buffy for a development package. The commit is published on LibGroupBuffs branch
`feat/buffy-appearance`, so remote package CI can fetch the pinned SHA.
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

The owner chose an alpha release before these in-game checks because the beta is closing.
Buffy may ship `v0.1.1-alpha1` after the companion PRs merge and package CI passes, using
the published immutable LibGroupBuffs commit pin above. Do not mark these scenarios as
verified. When the game is available again, test the exact merged library revision; then
tag it `r33` and replace Buffy's development commit pin before a stable release.

## Deferred GlassUI integration

GlassUI PR #160 and its hub roster entry are planned after Buffy v0.1.0. These
checks do not block this release:

- Test GlassUI absent, follow on/off, Pearl, clear/smoked/class tint, and gold/ice accent.
  Change each and reload. Confirm the hub shows pending reload and the effective appearance.
  Local opacity should be disabled while following and restored when follow is off.
- Enable the matching original addon once. Confirm Buffy can follow GlassUI while the original
  keeps its own material and opacity, regardless of library load order.

Record client build, addon/library revision, class, steps, and results before claiming runtime
acceptance or releasing. The newest API dump inspected during implementation was 1.60.1.70532.
