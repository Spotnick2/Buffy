# In-game acceptance

## Owner feedback after development deployment

The owner reports that Buffy works well on **Priest and Mage**, and has confirmed
**Mark of the Wild works on Druid**.

This feedback follows the deployment recorded in IMPLEMENTATION.md (client 1.60.1.70532,
Buffy `dev`, LibGroupBuffs commit `13f637b68f337a3a4aac8d69c9c9c70b7ed42fd4`, LibGlass r11).
Individual checklist scenarios were not specified, so this records general successful use
on Priest and Mage and Mark of the Wild on Druid without marking every scenario below as verified.
Other Druid behavior, including Thorns modes and Gift of the Wild, was not specified.

## Detailed checklist

Not performed by offline tests. Use the exact companion library revision and GlassUI roster
change recorded in IMPLEMENTATION.md. Disable the matching original addon for the main pass;
then explicitly test coexistence in the final appearance check.

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
- Test GlassUI absent, follow on/off, Pearl, clear/smoked/class tint, and gold/ice accent.
  Change each and reload. Confirm the hub shows pending reload and the effective appearance.
  Local opacity should be disabled while following and restored when follow is off.
- Enable the matching original addon once. Confirm Buffy can follow GlassUI while the original
  keeps its own material and opacity, regardless of library load order.
- Change class settings and position; exit the entire client and restart. Verify settings
  persist. Check another character of the same class shares buff settings but has separate
  position/visibility, and a different class has its own profile. `/reload` alone is insufficient.

Record client build, addon/library revision, class, steps, and results before claiming runtime
acceptance or releasing. The newest API dump inspected during implementation was 1.60.1.70532.
