local H = dofile("tests/harness.lua")
for _, class in ipairs({ "PRIEST", "DRUID", "MAGE" }) do
    local B = H.load(class)
    if class == "MAGE" then SlashCmdList.BUFFY("hide") end
    local oldPreference = B.WindowState("visible")
    SlashCmdList.BUFFY("test 5")
    H.check(B.previewActive and B.ui:IsPreview(), class .. " enters test mode")
    H.eq(#B.ui.rows, B.ui:Capacity() * #B.class.defs, class .. " row pool remains class-specific")
    H.eq(B.WindowState("visible"), oldPreference, class .. " preview does not change saved visibility")
    H.eq(B.WindowState("pos"), nil, class .. " preview does not save position")
    local shown = 0
    for _, row in ipairs(B.ui.rows) do
        if row._active then shown = shown + 1 end
        H.eq(row:GetAttribute("type1"), nil, class .. " preview cannot cast")
    end
    H.eq(shown, 5 * #B.class.defs, class .. " five groups show every buff")
    H.check(#B.ui.footerItems > 0, class .. " preview includes a reagent footer")
    SlashCmdList.BUFFY("test 8")
    shown = 0
    for _, row in ipairs(B.ui.rows) do if row._active then shown = shown + 1 end end
    H.eq(shown, 8 * #B.class.defs, class .. " eight groups shown")
    WoW.inCombat = true
    SlashCmdList.BUFFY("test off")
    H.check(B.previewExitPending and B.ui:IsPreview(), class .. " exit deferred in combat")
    WoW.inCombat = false
    WoW.dispatch("PLAYER_REGEN_ENABLED")
    WoW.flushTimers()
    H.check(not B.previewActive and not B.ui:IsPreview(), class .. " exits after combat")
    H.eq(B.WindowState("visible"), oldPreference, class .. " preference survives preview")
    if class == "MAGE" then H.check(not B.ui:IsVisible(), "preview restores a hidden window") end
    H.eq(#WoW.combatWrites, 0, class .. " preview causes no protected combat writes")
end

local B = H.load("PRIEST")
SlashCmdList.BUFFY("hide")
H.eq(B.WindowState("visible"), false, "manual hide before preview")
SlashCmdList.BUFFY("test 5")
WoW.groupMembers = 2
WoW.SetUnit("party1", { name = "New Group Member", class = "MAGE" })
WoW.dispatch("GROUP_JOINED")
WoW.dispatch("GROUP_ROSTER_UPDATE")
SlashCmdList.BUFFY("test off")
WoW.flushTimers()
H.eq(B.WindowState("visible"), true, "joining during preview restores group visibility")
H.check(B.ui:IsVisible(), "live group opens after preview")
H.check(not B.ui:IsPreview(), "group join clears synthetic roster")

B = H.load("DRUID")
SlashCmdList.BUFFY("hide")
SlashCmdList.BUFFY("test 5")
B.SetConfig("showSolo", true)
SlashCmdList.BUFFY("test off")
WoW.flushTimers()
H.eq(B.WindowState("visible"), true, "solo toggle during preview updates preference")
H.check(B.ui:IsVisible(), "enabling solo during preview opens live window")
SlashCmdList.BUFFY("test 5")
B.SetConfig("showSolo", false)
SlashCmdList.BUFFY("test off")
WoW.flushTimers()
H.check(not B.ui:IsVisible(), "disabling solo during preview closes live window")

B = H.load("MAGE")
SlashCmdList.BUFFY("hide")
SlashCmdList.BUFFY("test 5")
SlashCmdList.BUFFY("test off")
WoW.flushTimers()
H.eq(B.WindowState("visible"), false, "preview without a join preserves manual hide")
H.check(not B.ui:IsVisible(), "manual hide remains effective after preview")

B = H.load("MAGE")
WoW.groupMembers = 2
WoW.SetUnit("party1", { name = "Existing Member", class = "PRIEST" })
B.visibility:RosterChanged()
WoW.flushTimers()
SlashCmdList.BUFFY("hide")
SlashCmdList.BUFFY("test 5")
WoW.dispatch("GROUP_ROSTER_UPDATE")
SlashCmdList.BUFFY("test off")
WoW.flushTimers()
H.eq(B.WindowState("visible"), false, "group roster churn preserves manual hide")
H.check(not B.ui:IsVisible(), "manual hide stays closed without a new join")
H.done("preview")
