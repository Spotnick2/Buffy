local H = dofile("tests/harness.lua")
for _, class in ipairs({ "PRIEST", "DRUID", "MAGE", "WARRIOR" }) do
    local B = H.load(class)
    H.eq(B.classToken, class, "detected class")
    if class == "WARRIOR" then
        H.eq(B.engine, nil, "unsupported: no engine")
        H.eq(B.ui, nil, "unsupported: no window")
        SlashCmdList.BUFFY("show")
    else
        H.check(B.engine ~= nil and B.ui ~= nil and B.visibility ~= nil, "one active host")
        H.eq(B.engine.defs, B.classes[class].defs, "only selected definitions")
        local profiles = 0
        for _ in pairs(BuffyAccountDB.classes) do profiles = profiles + 1 end
        H.eq(profiles, 1, "only active class profile created")
        B.SetConfig("showSolo", true)
        WoW.flushTimers()
        H.check(B.ui:IsVisible(), "solo toggle opens")
        H.eq(B.ui:MainFrame():GetScale(), 1, "scale default")
        SlashCmdList.BUFFY("hide")
        H.eq(B.WindowState("visible"), false, "manual hide remembered")
        SlashCmdList.BUFFY("show")
        H.eq(B.WindowState("visible"), true, "show preference")
        H.check(B.ui:IsVisible(), "show command")
        local def = B.class.defs[1]
        local left, right = B.engine:ClickSpells(def)
        H.eq(left, def.sngl, "single fallback")
        H.eq(right, def.sngl, "right single")
        WoW.Know(def.grpID, def.grp, "Rank 1")
        WoW.dispatch("SPELLS_CHANGED")
        left, right = B.engine:ClickSpells(def)
        H.eq(left, def.grp, "group when learned")
        H.eq(right, def.sngl, "right remains single")
        H.check(#B.class.footerItems() > 0, "group reagent")
        B.optionsPanel:GetScript("OnShow")(B.optionsPanel)
        H.check(B.optionsPanel.built, "options build")
        H.check(B.optionsPanel.controls.frameScale ~= nil, "scale on every class")
        SlashCmdList.BUFFY("help")
        SlashCmdList.BUFFY("pos")
        WoW.inCombat = true
        SlashCmdList.BUFFY("hide")
        H.check(B.ui:MainFrame():IsShown(), "combat hide deferred")
        B.SetConfig("frameScale", 1.5)
        H.eq(B.ui:MainFrame():GetScale(), 1, "combat scale deferred")
        WoW.inCombat = false
        WoW.dispatch("PLAYER_REGEN_ENABLED")
        H.eq(B.ui:IsVisible(), false, "closed after combat")
        SlashCmdList.BUFFY("show")
        H.eq(B.ui:MainFrame():GetScale(), 1.5, "scale applied after combat")
        H.eq(#WoW.combatWrites, 0, "no secure writes in combat")
    end
end
H.done("host")
