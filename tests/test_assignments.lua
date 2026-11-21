-- Raid assignments through Buffy (#64): the handle is wired before the engine,
-- the window follows the group's assignments, Fear Ward exists only when
-- assigned, preview ignores assignment changes, and /buffy assign opens the
-- library's panel. The protocol itself is LibGroupBuffs' tests/test_assign.lua.
local H = dofile("tests/harness.lua")

local function Rows(B, id)
    local n = 0
    for _, r in ipairs(B.ui.rows) do
        if r._active and r._def and r._def.id == id then n = n + 1 end
    end
    return n
end

-- A hello and one record from a group member, through the real event.
local function Hello(name, class, spells)
    WoW.dispatch("CHAT_MSG_ADDON", "LibGroupBuffs", "1^H^" .. class .. "^" .. spells .. "^0", "PARTY", name)
end
local stamp = 0
local function Record(key, value, from)
    stamp = stamp + 1
    WoW.dispatch("CHAT_MSG_ADDON", "LibGroupBuffs",
        table.concat({ "1", "A", key, tostring(GetServerTime() + 100 + stamp), from, value }, "^"), "PARTY", from)
end

local function Party(B, others)
    WoW.groupMembers = #others + 1
    for i, o in ipairs(others) do WoW.SetUnit("party" .. i, o) end
    WoW.dispatch("GROUP_ROSTER_UPDATE")
    WoW.flushTimers()
    B.ui:Update()
    WoW.flushTimers()
end

------------------------------------------------------------
-- Priest: an owner elsewhere hides the row; Fear Ward appears when assigned
------------------------------------------------------------

do
    local B = H.load("PRIEST")
    H.check(B.assign ~= nil, "Buffy has an assignments handle")
    H.eq(B.engine.assignments, B.assign, "and the engine reads it")
    local fear
    for _, d in ipairs(B.class.defs) do if d.id == "fearward" then fear = d end end
    H.check(fear and fear.assignOnly and fear.assign == "targets", "Fear Ward is an assign-only target def")
    H.eq(fear.snglID, 6346, "spell 6346")
    -- Owning a raid-wide slot takes the group form.
    WoW.Know(21562, "Prayer of Fortitude"); WoW.Know(27681, "Prayer of Spirit")
    WoW.dispatch("SPELLS_CHANGED")
    WoW.flushTimers()

    Party(B, { { name = "Bren Holt", class = "PRIEST" }, { name = "Tank Person", class = "WARRIOR", role = "TANK" } })
    SlashCmdList.BUFFY("show")
    WoW.flushTimers()
    H.check(B.ui:IsVisible(), "the window is up in the party")
    H.check(Rows(B, "fort") > 0, "Fortitude has its row before any assignment")
    H.eq(Rows(B, "fearward"), 0, "and Fear Ward has none")

    Hello("Bren Holt", "PRIEST", "21562,27681,27683,6346")
    Record("1243", "Bren Holt", "Bren Holt")
    WoW.flushTimers()
    H.eq(B.assign:Owner(B.class.defs[1]), "Bren Holt", "Bren owns Fortitude")
    H.eq(Rows(B, "fort"), 0, "so this priest's window drops the Fortitude row")
    H.check(Rows(B, "spirit") > 0, "and keeps the rest")

    Record("6346:Buffy Test", "Tank Person", "Bren Holt")
    WoW.flushTimers()
    H.eq(Rows(B, "fearward"), 1, "Fear Ward targets give a Fear Ward row")
    local row
    for _, r in ipairs(B.ui.rows) do if r._active and r._def.id == "fearward" then row = r end end
    H.eq(#row._members, 1, "covering only the assigned player")
    H.eq(row._members[1].unit, "party2", "the tank")

    -- Turning Fortitude tracking off does not matter once it is assigned to me.
    B.SetConfig("trackFort", false)
    Record("1243", "Buffy Test", "Bren Holt")
    WoW.flushTimers()
    H.check(Rows(B, "fort") > 0, "an assigned buff shows even with its toggle off")

    -- Preview shows its own roster and ignores assignment changes.
    SlashCmdList.BUFFY("test 5")
    H.check(B.previewActive, "test mode")
    H.eq(Rows(B, "fearward"), 0, "no Fear Ward row in preview")
    Record("1243", "Bren Holt", "Bren Holt")
    WoW.flushTimers()
    H.check(B.previewActive and Rows(B, "fort") > 0, "an assignment change does not touch the preview")
    SlashCmdList.BUFFY("test off")
    WoW.flushTimers()
    H.eq(Rows(B, "fort"), 0, "leaving test mode applies it")

    -- The panel.
    SlashCmdList.BUFFY("assign")
    local c = LibStub("LibGroupBuffs-1.0").assign
    H.check(c.panel and c.panel:IsShown(), "/buffy assign opens the panel")
    SlashCmdList.BUFFY("assign")
    H.check(not c.panel:IsShown(), "and closes it")
end

------------------------------------------------------------
-- Druid: a Thorns list replaces the Thorns mode while it is set
------------------------------------------------------------

do
    local B = H.load("DRUID")
    B.SetConfig("thornsMode", "self")
    Party(B, { { name = "Dps Person", class = "ROGUE" } })
    SlashCmdList.BUFFY("show")
    WoW.flushTimers()
    local thorns
    for _, r in ipairs(B.ui.rows) do if r._active and r._def.id == "thorns" then thorns = r end end
    H.eq(thorns and thorns._members[1].unit, "player", "Thorns mode self: only the druid")
    Hello("Dps Person", "ROGUE", "")
    Record("467:Buffy Test", "Dps Person", "Dps Person")
    WoW.flushTimers()
    thorns = nil
    for _, r in ipairs(B.ui.rows) do if r._active and r._def.id == "thorns" then thorns = r end end
    H.check(thorns ~= nil and #thorns._members == 1 and thorns._members[1].unit == "party1",
        "an assigned non-tank gets Thorns, whatever the mode")
    B.SetConfig("thornsMode", "disabled")
    WoW.flushTimers()
    thorns = nil
    for _, r in ipairs(B.ui.rows) do if r._active and r._def.id == "thorns" then thorns = r end end
    H.check(thorns ~= nil, "even with Thorns disabled")
end

------------------------------------------------------------
-- Mage: the Magic slot gives the owner the chosen spell only
------------------------------------------------------------

do
    local B = H.load("MAGE")
    B.SetConfig("amplifyMode", "always")
    B.SetConfig("dampenMode", "always")
    Party(B, { { name = "Nils Frost", class = "MAGE" } })
    SlashCmdList.BUFFY("show")
    WoW.flushTimers()
    H.check(Rows(B, "amplify") > 0 and Rows(B, "dampen") > 0, "both rows before any assignment")
    Hello("Nils Frost", "MAGE", "1008,23028,604")
    Record("1008", "Buffy Test,604", "Nils Frost")
    WoW.flushTimers()
    H.eq(Rows(B, "amplify"), 0, "the Magic owner chosen for Dampen loses the Amplify row")
    H.check(Rows(B, "dampen") > 0, "and keeps Dampen")
    Record("1008", "Nils Frost,1008", "Nils Frost")
    WoW.flushTimers()
    H.eq(Rows(B, "amplify") + Rows(B, "dampen"), 0, "another mage's Magic slot hides both")
end

H.done("assignments")
