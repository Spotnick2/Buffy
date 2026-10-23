local B = Buffy
local API = B.API
if not API then return end
local C = {}
B.classes.PRIEST = C
local function KnowsSpell(...) return API.KnowsSpell(...) end
local function ItemIcon(...) return API.ItemIcon(...) end
local DEFS = {
    {
        id          = "fort",
        grpID       = 21562,
        snglID      = 1243,
        grp         = "Prayer of Fortitude",
        sngl        = "Power Word: Fortitude",
        fallbackIcon= "Interface\\Icons\\Spell_Holy_WordFortitude",
        duration    = 3600,
    },
    {
        id          = "spirit",
        grpID       = 27681,
        snglID      = 14752,
        grp         = "Prayer of Spirit",
        sngl        = "Divine Spirit",
        fallbackIcon= "Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
        duration    = 3600,
    },
    {
        id          = "shadow",
        grpID       = 27683,
        snglID      = 976,
        grp         = "Prayer of Shadow Protection",
        sngl        = "Shadow Protection",
        fallbackIcon= "Interface\\Icons\\Spell_Holy_PrayerOfShadowProtection",
        duration    = 600,
        visibility  = "shadow",   -- also gated by the Shadow Protection mode
    },
}
local DEFAULTS = {
    trackFort       = true,
    trackSpirit     = true,
    shadowMode      = "detect",   -- "always" | "detect" | "instance"
    showSolo        = false,
    trackPets       = true,
    frameAlpha      = 0.96,
    frameScale      = 1.00,
    popoverSide     = "auto",     -- "auto" | "left" | "right"
    lockFrame       = false,
    showClickHints  = true,
}
DEFAULTS.frameScale = 1
C.defs, C.defaults = DEFS, DEFAULTS
local PRIEST_ICON = "Interface\\Icons\\ClassIcon_Priest"
local HOLY_CANDLE_ID, SACRED_CANDLE_ID, LIGHT_FEATHER_ID = 17028, 17029, 17056
local function EligibleMembers(def, members)
    if def.id ~= "fort" then return members end
    local out = {}
    for _, member in ipairs(members) do
        if member.class ~= "PET_HUNTER" and member.class ~= "PET_WARLOCK" then
            out[#out + 1] = member
        end
    end
    return out
end

local SPEC_ICON_SPELLS = {
    { id = 15473, icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" },   -- Shadowform
    { id = 10060, icon = "Interface\\Icons\\Spell_Holy_WordFortitude" },      -- Power Infusion
    { id = 724,   icon = "Interface\\Icons\\Spell_Holy_SummonLightwell" },    -- Lightwell
}

local function GetSpecIcon()
    for _, s in ipairs(SPEC_ICON_SPELLS) do
        if KnowsSpell(s.id) then return s.icon end
    end
    return PRIEST_ICON
end


local function GetPrayerRank()
    local fort = DEFS[1]
    if not fort.grp then return 0 end
    return (API.GetSpellRank(fort.grp))
end

local function GetCandleInfo()
    local rank = GetPrayerRank()
    if rank == nil then return nil, nil, nil end
    if rank <= 0 then return nil, nil, nil end
    if rank == 1 then
        return HOLY_CANDLE_ID, ItemIcon(HOLY_CANDLE_ID), "Holy Candle"
    else
        return SACRED_CANDLE_ID, ItemIcon(SACRED_CANDLE_ID), "Sacred Candle"
    end
end


local LEVITATE_ID = 1706

local function FooterItems()
    local items = {}
    local candleID, candleIcon = GetCandleInfo()
    if candleID then
        items[#items + 1] = {
            itemID = candleID, icon = candleIcon, usedBy = "the group Prayers",
            color = function(count)
                if count >= 50 then return 0.20, 1.00, 0.20 end
                if count >= 25 then return 1.00, 0.88, 0.10 end
                return 1.00, 0.22, 0.10
            end,
        }
    end
    if KnowsSpell(LEVITATE_ID) then
        items[#items + 1] = {
            itemID = LIGHT_FEATHER_ID, icon = ItemIcon(LIGHT_FEATHER_ID), usedBy = "Levitate",
            color = function(count)
                if count > 0 then return 1.00, 1.00, 1.00 end
                return 0.50, 0.50, 0.50
            end,
        }
    end
    return items
end

C.membersFor = EligibleMembers
C.appearance = function() return { icon = GetSpecIcon() } end
C.footerItems = FooterItems
C.refresh = function() GetPrayerRank() end
C.icon = PRIEST_ICON
C.enabledKeys = { fort = "trackFort", spirit = "trackSpirit" }
C.modeKeys = { shadow = "shadowMode" }
C.reopenForAura = true
local INSTANCE_DB = {
    { name = "The Barrow Deeps", category = "Raids", default = true,
      tooltip = "10 player. NEW in Forever. Encounters are not catalogued yet - pre-checked because a raid "
      .. "is where missing Shadow Protection costs the most, while an unnecessary row costs "
      .. "little." },
    { name = "Hyjal Summit", category = "Raids", default = true,
      tooltip = "20 player. NEW in Forever. Encounters are not catalogued yet - pre-checked for the same "
      .. "reason. Note this is Forever's own raid, not the TBC one of the same name." },
    { name = "Onyxia's Lair", category = "Raids", default = false,
      tooltip = "40 player. Primarily Fire damage (Breath, Fireball)." },

    { name = "Ragefire Chasm", category = "Dungeons", default = true,
      tooltip = "Levels 13-18. Jergosh the Invoker casts Shadow Bolt and Curse of Weakness." },
    { name = "The Hall of Thanes", category = "Dungeons", default = false,
      tooltip = "Levels 13-18. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Ruins of Lordaeron", mapID = 2999, category = "Dungeons", default = false,
      tooltip = "Levels 15-20. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Wailing Caverns", category = "Dungeons", default = false,
      tooltip = "Levels 15-25. Primarily Nature and poison damage." },
    { name = "The Deadmines", category = "Dungeons", default = false,
      tooltip = "Levels 18-23. Primarily physical and Fire damage." },
    { name = "Shadowfang Keep", category = "Dungeons", default = true,
      tooltip = "Levels 22-30. Arugal (Shadow Bolt, Void Bolt), Wolf Master Nandos, and shadow casters "
      .. "throughout." },
    { name = "The Stockade", category = "Dungeons", default = false,
      tooltip = "Levels 22-30. Primarily physical damage." },
    { name = "Excavation Site: Wetlands", category = "Dungeons", default = false,
      tooltip = "Levels 24-29. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Blackfathom Deeps", category = "Dungeons", default = false,
      tooltip = "Levels 24-32. Twilight Lord Kelris casts Mind Blast; the rest is Nature and Frost." },
    { name = "City of Dalaran", category = "Dungeons", default = false,
      tooltip = "Levels 28-33. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Scarlet Monastery", category = "Dungeons", default = true,
      tooltip = "Levels 28-45, all four wings. Bloodmage Thalnos (Shadow Bolt) in the Graveyard; the "
      .. "Armory and Cathedral are physical. One entry because GetInstanceInfo() reports every "
      .. "wing under the same name." },
    { name = "Gnomeregan", category = "Dungeons", default = false,
      tooltip = "Levels 29-38. Primarily Nature, Fire and mechanical damage." },
    { name = "Razorfen Kraul", category = "Dungeons", default = false,
      tooltip = "Levels 30-40. Primarily Nature and poison damage." },
    { name = "The Drowned City", category = "Dungeons", default = false,
      tooltip = "Levels 35-40. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Krol'Dok Stronghold", category = "Dungeons", default = false,
      tooltip = "Levels 40-45. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Razorfen Downs", category = "Dungeons", default = true,
      tooltip = "Levels 40-50. Amnennar the Coldbringer deals Shadow and Frost damage; the rest is Nature." },
    { name = "Uldaman", category = "Dungeons", default = false,
      tooltip = "Levels 42-52. Primarily physical, Nature and Arcane damage." },
    { name = "Zul'Farrak", category = "Dungeons", default = true,
      tooltip = "Levels 44-54. Witch Doctor Zum'rah casts Shadow Bolt; the rest is Nature and physical." },
    { name = "Maraudon", category = "Dungeons", default = false,
      tooltip = "Levels 45-57, all entrances. Princess Theradras has a Shadow component; the rest is "
      .. "Nature. One entry: GetInstanceInfo() does not distinguish the entrances." },
    { name = "Alcaz Prison", category = "Dungeons", default = false,
      tooltip = "Levels 48-53. NEW in Forever. Encounters are not catalogued yet." },
    { name = "The Temple of Atal'Hakkar", category = "Dungeons", default = true,
      tooltip = "Levels 50-60. Shade of Eranikus (Shadow Bolt Volley), Jammal'an the Prophet (Shadow "
      .. "Bolt). Known to players as the Sunken Temple." },
    { name = "Blackrock Depths", category = "Dungeons", default = false,
      tooltip = "Levels 52-60. Ambassador Flamelash and scattered shadow casters. Generally not required." },
    { name = "Blackrock Spire", category = "Dungeons", default = false,
      tooltip = "Levels 55-60, Lower and Upper. Some shadow casters, generally not required. One entry "
      .. "because both halves share an instance name." },
    { name = "Blackmaw Hold", category = "Dungeons", default = false,
      tooltip = "Levels 55-60. NEW in Forever. Encounters are not catalogued yet." },
    { name = "Dire Maul", category = "Dungeons", default = true,
      tooltip = "Levels 58-60, all wings. Immol'thar (Shadow Bolt, Portal of Immol'thar); the West wing "
      .. "warlocks cast Shadow throughout." },
    { name = "Scholomance", category = "Dungeons", default = true,
      tooltip = "Levels 58-60. Darkmaster Gandling, Rattlegore, and heavy shadow trash throughout." },
    { name = "Stratholme", category = "Dungeons", default = true,
      tooltip = "Levels 58-60, both sides. Baron Rivendare (Shadow Bolt), Baroness Anastari (Shadow Bolt), "
      .. "undead shadow casters throughout." },
    { name = "Shaper's Terrace", category = "Dungeons", default = false,
      tooltip = "Levels 58-60. NEW in Forever. Encounters are not catalogued yet." },
}
C.instances = INSTANCE_DB
