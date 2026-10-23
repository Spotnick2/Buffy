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
H.done("preview")
