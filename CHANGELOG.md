# Changelog

## Unreleased

- Druid: hunter and warlock pets no longer count as missing Mark of the Wild or appear as its
  targets. Forever does not allow that buff on them. Other pet types are unchanged.
- Druid: Thorns in Everyone mode now includes pets when Track eligible pets is on. Self and tank
  modes are unchanged.
- Mage: hunter and warlock pets no longer count as missing Arcane Intellect or appear as its
  targets. Amplify and Dampen Magic are unchanged.
- `/buffy help` explains the two `?` marks separately (spell range unknown, or buff state
  unreadable), and counts any spell name it could not read from the client.

## v1.0.0 - 2026-11-04

- First stable release of Buffy 1.0. Same addon code as v1.0.0-beta1, now built on
  LibGroupBuffs r34 (beta1 used r33) and LibGlass r11.
- Changes since v0.1.0:
  - Add a battleground option for Priest Shadow Protection.
  - Add up/down window growth and `/buffy test [5|8|off]` to preview group layouts.
  - Add a reagent footer visibility option for each class.
  - Add optional vendor restocking for Priest candles, Druid Gift reagents, and Mage Arcane
    Powder. It is off by default.
- These changes have passed offline tests and package validation. Their in-game checks on the
  live client follow this release.

## v1.0.0-beta1

- First beta of Buffy 1.0. Same addon code and libraries as v0.1.1-alpha3 (LibGroupBuffs r33,
  LibGlass r11), now on the beta channel.
- Changes since v0.1.0:
  - Add a battleground option for Priest Shadow Protection.
  - Add up/down window growth and `/buffy test [5|8|off]` to preview group layouts.
  - Add a reagent footer visibility option for each class.
  - Add optional vendor restocking for Priest candles, Druid Gift reagents, and Mage Arcane Powder.
- This beta has passed offline tests and package validation; the new behavior still needs
  in-game checks on the live client.

## v0.1.1-alpha3

- Same addon code as v0.1.1-alpha2, now built on the LibGroupBuffs r33 release tag (the
  same library code). This build is for CurseForge, which didn't publish the earlier alphas.
- Add a battleground option for Priest Shadow Protection.
- Add up/down window growth and `/buffy test [5|8|off]` to preview group layouts.
- Add a reagent footer visibility option for each class.
- Add optional vendor restocking for Priest candles, Druid Gift reagents, and Mage Arcane Powder.
- This alpha has passed offline tests and package validation; the new behavior still needs in-game checks.

## v0.1.1-alpha2

- Same addon code as v0.1.1-alpha1, which was published on GitHub only. This build also
  goes to CurseForge and Wago Addons.
- Add a battleground option for Priest Shadow Protection.
- Add up/down window growth and `/buffy test [5|8|off]` to preview group layouts.
- Add a reagent footer visibility option for each class.
- Add optional vendor restocking for Priest candles, Druid Gift reagents, and Mage Arcane Powder.
- This alpha has passed offline tests and package validation; the new behavior still needs in-game checks.

## v0.1.1-alpha1

- Add a battleground option for Priest Shadow Protection.
- Add up/down window growth and `/buffy test [5|8|off]` to preview group layouts.
- Add a reagent footer visibility option for each class.
- Add optional vendor restocking for Priest candles, Druid Gift reagents, and Mage Arcane Powder.
- This alpha has passed offline tests and package validation; the new behavior still needs in-game checks.

## v0.1.0

- Initial Forever addon with automatic Priest, Druid, and Mage selection.
- Shared class profiles, per-character position/visibility, learned durations, and common scale control.
- One settings page, `/buffy` commands, class buff rules, targeting modes, and reagent counters.
- Optional GlassUI appearance with reload-based theme/tint/accent changes and standalone Clean fallback.
- Original shield branding, embedded library packaging, Lua tests, and package validation.
- Recheck hidden aura-detected Priest and Mage rows after relevant aura changes and combat.
