-- One host for all supported classes. Secure state and window policy belong to LibGroupBuffs.
local B = Buffy
if not B.API then return end
local API, GB = B.API, B.GB
local initialized, loggedIn, warnedNames, warnedRank, auraVisibilityPending

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
        footerItems = B.class.footerItems, glass = B.Material(),
        bodyStyle = B.FollowingSuite() and B.BodyStyle or nil,
        alpha = function() return B.Get("frameAlpha") end,
        scale = function() return B.Get("frameScale") end,
        locked = function() return B.Get("lockFrame") == true end,
        popoverSide = function() return B.Get("popoverSide") end,
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

local events = CreateFrame("Frame", "BuffyEvents")
B.events = events
B.RegisterEvents(events, "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
    "READY_CHECK", "UNIT_AURA", "UNIT_PET", "RAID_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", "GROUP_JOINED",
    "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_REGEN_ENABLED", "BAG_UPDATE",
    "SPELLS_CHANGED", "PLAYER_ROLES_ASSIGNED", "ROLE_CHANGED_INFORM")
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
        ui:OnCombatEnd()
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
        B.Say("/buffy [toggle|show|hide|config|reset|pos|help]")
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
