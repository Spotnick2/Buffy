# Buffy

Read [AGENTS.md](AGENTS.md) for project instructions, architecture, validation, and release rules.

## Consulting Codex

The shared `codex-consult` skill (user level) has the invocation and the gotchas. For this repo:

For Buffy specifically, good things to hand Codex: a class module in `Classes/` (targeting rules,
instance lists, reagent and restock data) checked against the original it was adapted from -
Priestly at `C:/Projects/WoW/Priestly`, Wildly at `C:/Projects/WoW/Wildly`, Magely at
`C:/Projects/WoW/Magely`; a change to the saved shape in `BuffyConfig.lua` (class profiles in
`BuffyAccountDB.classes`, per-character `BuffyDB`); the merchant restock path and preview mode in
`Buffy.lua`; and anything that might belong in LibGroupBuffs (`C:/Projects/WoW/LibGroupBuffs`)
rather than in Buffy, which must not copy the library's implementation.

**Always hand it `AGENTS.md`, `docs/ACCEPTANCE.md` and Priestly's `docs/FOREVER-PROBE.md`
alongside the diff.** Those findings are measured on the live client, and a cold reviewer will
otherwise argue from Classic-era or Retail behaviour that does not hold here - that auras throw for
the whole group in combat, that no SavedVariables survive a restart, that the client's secure
handler decides which mouse edge acts. `ACCEPTANCE.md` says what has and has not been checked in
game. The newest `C:/Projects/WoW/References/Forever/api/forever-api-<build>.md` is the full
measured API surface if a question turns on whether something exists.
