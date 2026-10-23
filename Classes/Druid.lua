local B = Buffy
local API = B.API
if not API then return end
local C = {}
B.classes.DRUID = C
local function KnowsSpell(...) return API.KnowsSpell(...) end
local function ItemIcon(...) return API.ItemIcon(...) end
local DEFS = {
    {
        id          = "mark",
        snglID      = 1126,
        grpID       = 21849,
        sngl        = "Mark of the Wild",
        grp         = "Gift of the Wild",
        fallbackIcon= "Interface\\Icons\\Spell_Nature_Regeneration",
        duration    = 1800,
    },
    {
        id          = "thorns",
        snglID      = 467,
        sngl        = "Thorns",
        fallbackIcon= "Interface\\Icons\\Spell_Nature_Thorns",
        duration    = 600,
    },
}
local DEFAULTS = {
    trackMark       = true,
    thornsMode      = "default",  -- "default" | "tanks" | "self" | "everyone" | "disabled"
    showSolo        = false,
    trackPets       = true,
    frameAlpha      = 0.96,
    popoverSide     = "auto",     -- "auto" | "left" | "right"
    lockFrame       = false,
    showClickHints  = true,
}
DEFAULTS.frameScale = 1
C.defs, C.defaults = DEFS, DEFAULTS
local DRUID_ICON = "Interface\\Icons\\ClassIcon_Druid"
local MARK = DEFS[1]
local g_GiftRank, g_SpecIcon
local RefreshDerived
local function IsPet(member)
    return type(member.class) == "string" and member.class:find("^PET") ~= nil
end

local g_Tanks

local function ForgetTanks() g_Tanks = nil end

local PARTY_UNITS = { "player", "party1", "party2", "party3", "party4" }

local function Tanks()
    if g_Tanks then return g_Tanks end
    local tanks = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitGroupRolesAssigned(unit) == "TANK"
                or select(10, GetRaidRosterInfo(i)) == "MAINTANK"
            then
                tanks[unit] = true
            end
        end
    else
        for _, unit in ipairs(PARTY_UNITS) do
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                tanks[unit] = true
            end
        end
    end
    g_Tanks = tanks
    return tanks
end

local function IsTank(unit) return Tanks()[unit] == true end

local function EffectiveMode()
    local mode = B.Get("thornsMode")
    if mode ~= "default" then return mode end
    if GetNumGroupMembers() > 0 and next(Tanks()) ~= nil then return "tanks" end
    return "self"
end

local function ThornsMembers(members)
    local mode = EffectiveMode()
    local out = {}
    for _, m in ipairs(members) do
        if not IsPet(m) then
            local include
            if mode == "everyone" then
                include = true
            elseif mode == "self" then
                include = UnitIsUnit(m.unit, "player")
            else -- "tanks"
                include = IsTank(m.unit)
            end
            if include then out[#out + 1] = m end
        end
    end
    return out
end

local function MembersFor(def, members)
    if def.id ~= "thorns" then return members end
    return ThornsMembers(members)
end

local SPEC_ICON_SPELLS = {
    { id = 24858, icon = "Interface\\Icons\\Spell_Nature_ForceOfNature" },  -- Moonkin Form
    { id = 18562, icon = "Interface\\Icons\\INV_Relics_IdolofRejuvenation" }, -- Swiftmend
    { id = 17007, icon = "Interface\\Icons\\Spell_Nature_UnyeildingStamina" }, -- Leader of the Pack
}

local function FindSpecIcon()
    for _, s in ipairs(SPEC_ICON_SPELLS) do
        if KnowsSpell(s.id) then return s.icon end
    end
    return DRUID_ICON
end

local function GetSpecIcon() return g_SpecIcon or DRUID_ICON end

local APPEARANCE = {
    border     = { 1.00, 0.49, 0.04, 0.85 },
    header     = { 0.16, 0.08, 0.03, 0.98 },
    headerLine = { 1.00, 0.49, 0.04, 0.55 },
    footerLine = { 0.95, 0.47, 0.06, 0.40 },
    popBorder  = { 0.95, 0.47, 0.06, 1 },
    popDivider = { 0.95, 0.47, 0.06, 0.55 },
}

local function Appearance()
    local look = { icon = GetSpecIcon() }
    for k, v in pairs(APPEARANCE) do look[k] = v end
    return look
end

local GIFT_REAGENTS = {
    [1] = 17021,   -- Wild Berries
    [2] = 17026,   -- Wild Thornroot
}

local function FindGiftRank()
    if not MARK.hasGroup then return 0 end
    return (API.GetSpellRank(MARK.grp))
end

local function GetGiftRank() return g_GiftRank or 0 end

RefreshDerived = function()
    g_GiftRank = FindGiftRank()
    g_SpecIcon = FindSpecIcon()
end

local function FooterItems()
    local items = {}
    if B.IsBuffEnabled and not B.IsBuffEnabled("mark") then return items end
    local reagent = GIFT_REAGENTS[GetGiftRank()]
    if reagent then
        items[#items + 1] = {
            itemID = reagent, icon = ItemIcon(reagent), usedBy = MARK.grp,
            color = function(count)
                if count >= 50 then return 0.20, 1.00, 0.20 end
                if count >= 25 then return 1.00, 0.88, 0.10 end
                return 1.00, 0.22, 0.10
            end,
        }
    end
    return items
end

C.membersFor, C.forgetRoster = MembersFor, ForgetTanks
C.appearance, C.footerItems, C.refresh = Appearance, FooterItems, RefreshDerived
C.icon = DRUID_ICON
C.enabledKeys = { mark = "trackMark" }
C.modeKeys = {}
C.thornsModes = { "default", "tanks", "self", "everyone", "disabled" }
C.effectiveMode, C.isTank = EffectiveMode, IsTank
C.instances = {}
