-- One host for all supported classes. Secure state and window policy belong to LibGroupBuffs.
local B = Buffy
if not B.API then return end
local API, GB = B.API, B.GB
local initialized, loggedIn, warnedNames, warnedRank, auraVisibilityPending
local pendingRestock = {}
local ReportRestock

function B.Say(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff99ddff[Buffy]|r " .. text) end
end

local function WarnSpells()
    if not loggedIn then return end
    local report = B.engine:SpellReport()
    for _, entry in ipairs(report) do
        for _, form in ipairs(entry.forms) do
            if not warnedNames and form.from == "fallback" and B.IsBuffEnabled(entry.id) then
                warnedNames = true
                B.Say("Some spell names could not be resolved; /buffy help shows the names being matched.")
            end
        end
    end
    if report.ranks and not warnedRank then
        warnedRank = true
        B.Say("A spell rank could not be read; its reagent count may be hidden. /buffy help has details.")
    end
end

local function RefreshSpells()
    B.engine:RefreshSpells()
    B.class.refresh()
    WarnSpells()
end

function B.OnConfigChanged(key)
    if not B.ui or not loggedIn then return end
    if key == "learnedDurations" or key == "pos" or key == "visible" then return end
    if B.previewActive then
        if InCombatLockdown() then B.previewRefreshPending = true else B.ui:Update() end
        return
    end
    if key == "frameAlpha" or key == "frameScale" then B.ui:ApplyAppearance()
    elseif key == "showSolo" then B.visibility:SoloToggled(B.Get("showSolo"))
    else
        WarnSpells()
        B.visibility:ContentChanged()
    end
end

local function Initialize()
    if initialized then return end
    initialized = true
    local _, token = UnitClass("player")
    B.classToken, B.class = token, B.classes[token]
    if not B.class then return end
    B.InitConfig()
    B.StartAppearance()
    B.engine = GB.Engine({
        defs = B.class.defs, bucketSize = 8,
        showSolo = function() return B.Get("showSolo") == true end,
        trackPets = function() return B.Get("trackPets") ~= false end,
        isBuffEnabled = B.IsBuffEnabled, isVisible = B.IsVisible,
        membersFor = B.class.membersFor,
        learnDuration = B.LearnDuration, learnedDuration = B.LearnedDuration,
    })
    B.ui = GB.UI({
        engine = B.engine, title = "|cff99ddffBuffy|r", version = API.AddonVersion("Buffy"),
        minimizable = true, appearance = B.Appearance, unknownClassIcon = B.class.icon,
        footerItems = function()
            return B.Get("showReagents") ~= false and B.class.footerItems() or {}
        end, glass = B.Material(),
        previewFooterItems = function()
            return B.Get("showReagents") ~= false and B.class.previewFooterItems() or {}
        end,
        bodyStyle = B.FollowingSuite() and B.BodyStyle or nil,
        alpha = function() return B.Get("frameAlpha") end,
        scale = function() return B.Get("frameScale") end,
        locked = function() return B.Get("lockFrame") == true end,
        popoverSide = function() return B.Get("popoverSide") end,
        growDirection = function() return B.Get("growDirection") end,
        showClickHints = function() return B.Get("showClickHints") ~= false end,
        getPos = function() return B.WindowState("pos") end,
        setPos = function(pos) B.SetWindowState("pos", pos) end,
        setVisible = function(v) B.SetWindowState("visible", v) end,
        onCloseDeferred = function(_, manual)
            B.Say(manual and "The window closes when combat ends."
                or "Nothing to show here now: the window closes when combat ends.")
        end,
        onMinimizeDeferred = function(_, minimized)
            B.Say("The window " .. (minimized and "minimizes" or "restores") .. " when combat ends.")
        end,
    })
    B.visibility = GB.Visibility({
        ui = B.ui, isMyClass = function() return loggedIn == true end,
        showSolo = function() return B.Get("showSolo") == true end,
        getPreference = function() return B.WindowState("visible") end,
        setPreference = function(v) B.SetWindowState("visible", v) end,
    })
end

local function EndPreview()
    if not B.previewActive then return end
    if InCombatLockdown() then
        B.previewExitPending = true
        B.Say("Test mode ends when combat ends.")
        return
    end
    B.previewExitPending = nil
    B.previewRefreshPending = nil
    B.previewActive = nil
    B.ui:SetPreview(nil)
    RefreshSpells()
    if B.previewWasVisible then B.ui:Update() else B.ui:Close() end
    B.previewWasVisible = nil
end

local function StartPreview(groups)
    if InCombatLockdown() then B.Say("Test mode can only start outside combat."); return end
    if not B.previewActive then B.previewWasVisible = B.ui:IsVisible() end
    B.previewActive = true
    B.ui:SetPreview(groups)
    B.ui:Update()
    B.Say("Test mode: " .. groups .. " groups. Use /buffy test off to return to live data.")
end

function B.RestockReagents()
    local restock = B.class and B.class.restock
    if not restock or B.Get(restock.enabledKey) ~= true then return end
    local wanted = {}
    for _, itemID in ipairs(restock.items()) do wanted[itemID] = true end
    local target = B.Get(restock.targetKey) or 80
    local money = API.Money()
    for index = 1, API.MerchantItemCount() do
        local itemID, info = API.MerchantItem(index)
        if itemID and wanted[itemID] and not pendingRestock[itemID] and info and info.isPurchasable
            and not info.hasExtendedCost and not info.currencyID then
            local pack = info.stackCount or 1
            local price = info.price
            local stock = info.numAvailable
            if type(pack) == "number" and pack > 0 and type(price) == "number" and price > 0
                and type(stock) == "number" and (stock == -1 or stock >= pack) then
                local before = API.CountItem(itemID)
                local need = target - before
                local room = API.ItemRoom(itemID)
                local affordable = math.floor(money / price) * pack
                local quantity = math.min(need, room, affordable)
                if stock >= 0 then quantity = math.min(quantity, stock) end
                quantity = math.floor(quantity / pack) * pack
                if quantity > 0 and API.BuyMerchantItem(index, quantity) then
                    wanted[itemID] = nil
                    pendingRestock[itemID] = before
                    money = money - (quantity / pack) * price
                    C_Timer.After(2, function() ReportRestock() end)
                end
            end
        end
    end
end

ReportRestock = function()
    for itemID, before in pairs(pendingRestock) do
        local gained = API.CountItem(itemID) - before
        if gained > 0 then
            B.Say("Bought " .. gained .. " " .. (B.class.restock.names[itemID] or "reagents") .. ".")
        end
        pendingRestock[itemID] = nil
    end
end

local events = CreateFrame("Frame", "BuffyEvents")
B.events = events
B.RegisterEvents(events, "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
    "READY_CHECK", "UNIT_AURA", "UNIT_PET", "RAID_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", "GROUP_JOINED",
    "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_REGEN_ENABLED", "BAG_UPDATE",
    "SPELLS_CHANGED", "PLAYER_ROLES_ASSIGNED", "ROLE_CHANGED_INFORM", "MERCHANT_SHOW", "BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "Buffy" then Initialize() end
        return
    end
    if event == "PLAYER_LOGIN" then
        Initialize()
        if not B.class then return end
        loggedIn = true
        B.RegisterOptions()
        if B.class.forgetRoster then B.class.forgetRoster() end
        RefreshSpells()
        B.ui:Init()
        B.visibility:Login()
        B.Say("Loaded. /buffy toggles the window; /buffy config opens settings.")
        return
    end
    if not loggedIn then return end
    if event == "MERCHANT_SHOW" then B.RestockReagents(); return end
    if event == "BAG_UPDATE_DELAYED" then ReportRestock(); return end
    if B.previewActive and event ~= "PLAYER_REGEN_ENABLED" then
        if event == "PLAYER_ENTERING_WORLD" then B.EnteringWorld(arg1, arg2) end
        return
    end
    local ui, vis, engine = B.ui, B.visibility, B.engine
    if event == "PLAYER_ENTERING_WORLD" then
        B.EnteringWorld(arg1, arg2)
        vis:ContentChanged()
    elseif event == "ZONE_CHANGED_NEW_AREA" then vis:ContentChanged()
    elseif event == "READY_CHECK" then vis:ReadyCheck()
    elseif event == "UNIT_AURA" then
        if engine:AuraEventIsRelevant(arg1, arg2) then
            if not ui:IsVisible() and B.class.reopenForAura then
                if InCombatLockdown() then auraVisibilityPending = true
                else vis:ContentChanged() end
            else
                ui:ScheduleRefresh()
            end
        end
    elseif event == "UNIT_PET" then ui:ScheduleRefresh()
    elseif event == "GROUP_JOINED" then
        if B.class.forgetRoster then B.class.forgetRoster() end
        vis:GroupJoined()
    elseif event == "RAID_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        if B.class.forgetRoster then B.class.forgetRoster() end
        engine:PruneCache()
        vis:RosterChanged()
    elseif event == "PLAYER_ROLES_ASSIGNED" or event == "ROLE_CHANGED_INFORM" then
        if B.class.forgetRoster then B.class.forgetRoster(); vis:ContentChanged() end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        RefreshSpells()
        ui:ApplyAppearance()
        if ui:IsVisible() and InCombatLockdown() then ui:RefreshFooter() else vis:ContentChanged() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if B.previewExitPending then EndPreview() end
        ui:OnCombatEnd()
        if B.previewActive and B.previewRefreshPending then
            B.previewRefreshPending = nil
            ui:Update()
        end
        if auraVisibilityPending then
            auraVisibilityPending = nil
            vis:ContentChanged()
        end
    elseif event == "BAG_UPDATE" and ui:IsVisible() then ui:RefreshFooter() end
end)

SLASH_BUFFY1 = "/buffy"
SlashCmdList.BUFFY = function(message)
    if not B.class then B.Say("Buffy manages Priest, Druid, and Mage buffs; this class is not supported."); return end
    if not loggedIn then B.Say("Buffy is waiting for login to finish."); return end
    local cmd = strtrim(message or ""):lower()
    local ui = B.ui
    if cmd == "test" or cmd:find("^test%s") then
        local arg = cmd:match("^test%s*(%S*)")
        if arg == "off" or (arg == "" and B.previewActive) then EndPreview()
        elseif arg == "" or arg == "5" or arg == "8" then StartPreview(tonumber(arg) or 5)
        else B.Say("Use /buffy test [5|8|off].") end
        return
    end
    if B.previewActive then
        EndPreview()
        if B.previewActive then return end
    end
    if cmd == "config" or cmd == "options" or cmd == "settings" then B.OpenConfig()
    elseif cmd == "hide" or cmd == "close" then ui:Close(true)
    elseif cmd == "show" then B.SetWindowState("visible", true); ui:Update()
    elseif cmd == "reset" then
        B.Say(ui:ResetPosition() and "Window position reset." or "Position reset; the window moves when combat ends.")
        if B.Get("lockFrame") then B.Say("The window is locked. Unlock it in /buffy config to move it.") end
    elseif cmd == "pos" then
        local pos = B.WindowState("pos")
        B.Say(pos and string.format("Saved position: %s/%s %s, %s", tostring(pos.point), tostring(pos.relPoint),
            tostring(pos.x), tostring(pos.y)) or "No saved position.")
        B.Say("Last restore: " .. tostring(ui:RestoreInfo().log) .. "; locked: " .. tostring(B.Get("lockFrame")))
    elseif cmd == "help" then
        B.Say("/buffy [toggle|show|hide|config|reset|pos|test|help]")
        B.Say("Left-click: group buff when learned, otherwise single. Right-click: single buff. Hover: member list.")
        B.Say("Timer: green >50%, yellow 10-50%, red <10%. ?: unreadable aura or unknown range.")
        local lib, minor = LibStub("LibGroupBuffs-1.0", true)
        local report = B.engine:SpellReport()
        B.Say("Locale " .. tostring(report.locale) .. ", build " .. tostring(API.ClientBuild())
            .. ", Buffy " .. tostring(API.AddonVersion("Buffy")) .. ", library r" .. tostring(minor)
            .. (lib.ready ~= minor and " (incomplete)" or ""))
        for _, entry in ipairs(report) do
            for _, form in ipairs(entry.forms) do
                B.Say(entry.id .. " " .. form.role .. ": " .. tostring(form.name) .. " (" .. tostring(form.from)
                    .. (form.known and ", learned)" or ", not learned)"))
            end
        end
        for _, rank in ipairs(report.ranks or {}) do
            B.Say("Unreadable rank: " .. tostring(rank.name) .. " / " .. tostring(rank.subtext))
        end
    elseif cmd == "" or cmd == "toggle" then
        if ui:IsVisible() then ui:Close(true) else B.SetWindowState("visible", true); ui:Update() end
    else B.Say("Unknown command. Use /buffy help.") end
end
