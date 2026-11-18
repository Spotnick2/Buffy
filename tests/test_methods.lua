-- test_methods.lua - every widget method Buffy's frames call exists on the client, for that
-- widget type (WowTestKit's Kit.checkMethods, against the build tests/kit.pin names).
--
-- The stub answers any method the build has on any widget, so the other tests can't tell a
-- FontString:SetTexCoord from a Texture's. This one exercises Buffy as widely as is cheap,
-- on each class:
--   * login, in a party;
--   * the window, the 5 and 8 previews;
--   * every frame with a script, hovered and clicked;
--   * the options panel and its controls;
--   * combat in and out, a merchant visit, and every slash command.
-- Then it checks each recorded Type:Method against the build's widget lists. The calls
-- include the libraries' (LibGroupBuffs draws the window, LibGlass its material): they run in
-- Buffy's frames, so they are checked too. The calls of every class are kept across the
-- reloads (Kit.freshClient keeps them in Kit.earlierMethodsCalled).
local H = dofile("tests/harness.lua")

-- Every frame made so far that has a script: hovered, clicked and left.
local function poke()
    for _, w in ipairs(WoW.frames) do
        for _, script in ipairs({ "OnEnter", "OnClick", "OnLeave" }) do
            local fn = w._scripts and w._scripts[script]
            if fn then
                local ok, err = pcall(fn, w, script == "OnClick" and "LeftButton" or nil, false)
                H.check(ok, (w._name or w._type) .. " " .. script .. ": " .. tostring(err))
            end
        end
    end
    WoW.flushTimers()
end

local function slash(cmd)
    local ok, err = pcall(SlashCmdList.BUFFY, cmd)
    H.check(ok, "/buffy " .. cmd .. ": " .. tostring(err))
    WoW.flushTimers()
end

for _, class in ipairs({ "PRIEST", "DRUID", "MAGE" }) do
    local B = H.load(class, nil, function()
        WoW.SetUnit("party1", { name = "Party Tank", class = "WARRIOR", role = "TANK" })
        WoW.SetUnit("party2", { name = "Party Healer", class = "PRIEST" })
        WoW.groupMembers = 3
    end)
    WoW.dispatch("GROUP_ROSTER_UPDATE")
    WoW.flushTimers()

    -- The window, live and in both previews.
    slash("show")
    poke()
    for _, cmd in ipairs({ "test 5", "test 8" }) do
        slash(cmd)
        poke()
    end
    slash("test off")

    -- The options panel, built on its OnShow, and its controls.
    local panel = B.optionsPanel
    H.check(panel ~= nil, class .. ": the options panel exists")
    local ok, err = pcall(panel:GetScript("OnShow"), panel)
    H.check(ok, class .. ": options OnShow: " .. tostring(err))
    poke()

    -- Combat in and out, with a roster change in between.
    WoW.inCombat = true
    WoW.dispatch("PLAYER_REGEN_DISABLED")
    WoW.SetUnit("party3", { name = "New Person", class = "ROGUE" })
    WoW.groupMembers = 4
    WoW.dispatch("GROUP_ROSTER_UPDATE")
    slash("hide")
    WoW.inCombat = false
    WoW.dispatch("PLAYER_REGEN_ENABLED")
    WoW.flushTimers()

    -- A merchant visit with restock on.
    B.SetConfig(B.class.restock.enabledKey, true)
    WoW.merchantItems = { { itemID = 17028, price = 100, numAvailable = -1, stackCount = 1, isPurchasable = true } }
    WoW.money = 100000
    WoW.dispatch("MERCHANT_SHOW")
    WoW.flushTimers()

    -- Every slash command.
    for _, cmd in ipairs({ "help", "show", "pos", "reset", "toggle", "toggle", "config", "test 9", "bogus", "hide" }) do
        slash(cmd)
    end
end

local recorded = Kit.checkMethods()
-- The floor is what the exercise records today (121 on build 70959), rounded down: it keeps the
-- exercise from quietly shrinking.
H.check(recorded >= 120, "the exercise reached the window, previews and options (" .. recorded .. " recorded)")

H.done("methods")
