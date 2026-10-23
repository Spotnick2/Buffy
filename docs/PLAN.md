# Buffy: merged Forever buff manager

## Summary

Deliver one working addon that automatically selects Priest, Druid, or Mage behavior from Priestly, Wildly, and Magely. Use LibGroupBuffs for buff logic, secure casting, window behavior, and settings infrastructure; use LibGlass for rendering.

The first milestone includes repository initialization, all three classes, GlassUI integration, branding, packaging, and automated tests. Settings start fresh and are shared by class; window position and visibility remain per character.

## Buffy implementation

- Initialize a local Git repository with `main` and an implementation branch. Adapt the sibling instructions into Buffy-specific `AGENTS.md` and a `CLAUDE.md` pointer, including Forever API references, secure UI rules, validation, and release conventions.
- Set addon identity to **Buffy**, author **Spotnick**, Interface **16001**, CurseForge project **1760483**, and version placeholder `@project-version@`. Preserve the supplied PNG as the source logo and produce a game-compatible texture for the TOC and settings page. Retain class/spec icons in the buff window.
- Build one shared bootstrap, configuration layer, event dispatcher, and command handler, with separate Priest, Druid, and Mage definition modules. Instantiate only the detected class’s engine, window, and visibility controller.
- Preserve the existing class behavior:
  - **Priest:** Fortitude, Spirit, Shadow Protection modes and instance selections, reagent tracking, and current pet eligibility rules.
  - **Druid:** Mark/Gift of the Wild, all five Thorns targeting modes, tank detection, and reagent tracking.
  - **Mage:** Intellect/Brilliance, independent Amplify/Dampen modes and instance selections, and reagent tracking.
- Preserve learned durations, localized spell resolution, single-target fallback before group spells are learned, group/popover behavior, combat deferral, and available diagnostics.
- Provide `/buffy` with toggle, show, hide, config, reset, pos, and help commands. Unsupported classes create no buff window and receive an explanation when invoking the command.
- Store class profiles under `BuffyAccountDB.classes`, keyed by class token. Each holds buff settings, standalone appearance preferences, and learned durations. Store position and visibility in per-character `BuffyDB`. Route writes through the configuration layer.
- Present one Buffy settings category containing common controls and the active class’s options. Use existing class defaults; expose Priestly’s scale control consistently for all three classes.

## Shared-library and GlassUI integration

- Resolve the library version mismatch first: Priestly pins `r31`, while the local LibGroupBuffs checkout contains `r29`. Base the companion change on current upstream code, preserving existing work.
- Extend LibGroupBuffs’ `GB.UI(host)` contract with an optional per-window LibGlass instance and body-style callback. The body descriptor supports tint, wash multiplier, and masked backing. Thread the selected material through panels, headers, and row decoration; omitted options retain existing behavior.
- Keep the extension additive and preserve LibStub upgrade behavior. Buffy must never change the library’s shared material instance or copy its UI implementation.
- Add `{ name = "Buffy", title = "Buffy", dynamic = true }` to GlassUI’s roster, matching AltStable’s loaded-only listing. Use the existing public suite contract; no new registration API is needed.
- Declare `OptionalDeps: GlassUI`. After saved settings load and before creating glass, validate `Suite.API == 1` and call `Theme`, `Look`, `Body`, and `Accent` defensively.
- Follow the suite’s material, body tint/backing, and decorative accent. Preserve buff-status colors and class/spec icons. Report effective tint and accent, library revision, an options callback, and `live = false`.
- Apply suite changes after reload. While following, suspend Buffy’s local opacity override and explain its disabled control. Keep the saved local value for when following is disabled.
- With GlassUI absent, incompatible, or declining participation, use the existing Clean appearance. Report material failures accurately and retain a usable standalone fallback when possible.
- Make companion changes as separate reviewable changes in their owning repositories. Preserve GlassUI’s existing uncommitted edits; LibGlass itself needs no change.

## Packaging and validation

- Adapt sibling test/deploy tooling and the shared release templates. Embed LibGlass and LibGroupBuffs side by side at their standard paths, using immutable pins and excluding development files from packages.
- Pin LibGlass `r11` and the LibGroupBuffs revision containing the new interface. A development commit pin may be used during integration; release packaging uses the resulting library tag.
- Add player documentation, an initial changelog, and licensing for the actual bundled dependencies. Configure CurseForge metadata and GitHub package checks; defer Wago configuration until a project ID is supplied.
- Run Lua 5.1 syntax checks and tests covering:
  - Class detection, unsupported classes, and exactly one active engine/window.
  - Each class’s buff selection, targeting, reagents, visibility, and localized spells.
  - Profile isolation between classes, sharing within a class, and per-character window state.
  - Combat entry, deferred opening/closing, roster changes, and secure click mappings.
  - GlassUI absence, malformed responses, follow on/off, reload indicators, and material failures.
  - Independent appearances when Buffy and an original addon coexist, including library upgrades.
  - TOC load order, dependency pins, logo inclusion, and package contents.
- Run affected LibGroupBuffs and GlassUI suites plus the three original addon suites against the companion library change. Use the newest available Forever API dump, currently **1.60.1.70532**, without presenting API presence as runtime verification.
- Require in-game acceptance for each supported class, combat casting, main window/popover rendering, GlassUI tint/accent after reload, and settings persistence after a full client restart.

## Assumptions and completion boundary

- No legacy settings import or reuse of the original addons’ slash commands. Document disabling the matching original addon when using Buffy to avoid duplicate windows.
- Preserve the supplied artwork; no redesign or additional classes.
- Initialize locally and prepare release tooling. Remote repository creation, release tags, publishing, and game-folder deployment are separate actions.
- Companion repositories require writable access during implementation; this session currently permits writes only within Buffy.
- Complete this as one working-addon milestone, then report changed files, commands and test results, remaining in-game checks, and the recommended next prompt. Offline completion does not imply in-game acceptance.
