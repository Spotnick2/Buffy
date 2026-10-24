local B = Buffy
local API = B.API
if not API then return end
local C = {}
B.classes.MAGE = C
local function KnowsSpell(...) return API.KnowsSpell(...) end
local function ItemIcon(...) return API.ItemIcon(...) end
local DEFS = {
    {
        id          = "intellect",
        snglID      = 1459,
        grpID       = 23028,
        sngl        = "Arcane Intellect",
        grp         = "Arcane Brilliance",
        fallbackIcon= "Interface\\Icons\\Spell_Holy_MagicalSentry",
        duration    = 3600,
    },
    {
        id          = "amplify",
        snglID      = 1008,
        sngl        = "Amplify Magic",
        fallbackIcon= "Interface\\Icons\\Spell_Holy_FlashHeal",
        duration    = 600,
    },
    {
        id          = "dampen",
        snglID      = 604,
        sngl        = "Dampen Magic",
        fallbackIcon= "Interface\\Icons\\Spell_Nature_AbolishMagic",
        duration    = 600,
    },
}
local DEFAULTS = {
    trackIntellect  = true,
    trackAmplify    = true,
    trackDampen     = true,
    amplifyMode     = "detect",   -- "always" | "detect" | "instance"
    dampenMode      = "detect",   -- "always" | "detect" | "instance"
    showSolo        = false,
    trackPets       = true,
    frameAlpha      = 0.96,
    growDirection   = "down",
    popoverSide     = "auto",     -- "auto" | "left" | "right"
    lockFrame       = false,
    showClickHints  = true,
    showReagents    = true,
    autoBuyPowder   = false,
    powderTarget    = 80,
}
DEFAULTS.frameScale = 1
C.defs, C.defaults = DEFS, DEFAULTS
local MAGE_ICON = "Interface\\Icons\\ClassIcon_Mage"
local INTELLECT = DEFS[1]
local g_Spec
local RefreshDerived
local SPECS = {
    { id = 12042, key = "ARCANE", icon = "Interface\\Icons\\Spell_Nature_StarFall",
      color = { 0.35, 0.62, 1.00 } },                                   -- Arcane Power
    { id = 11129, key = "FIRE",   icon = "Interface\\Icons\\Spell_Fire_FireBolt02",
      color = { 1.00, 0.43, 0.16 } },                                   -- Combustion
    { id = 11426, key = "FROST",  icon = "Interface\\Icons\\Spell_Frost_FrostBolt02",
      color = { 0.39, 0.90, 1.00 } },                                   -- Ice Barrier
}
local PLAIN_MAGE = { key = "MAGE", icon = MAGE_ICON, color = { 0.25, 0.78, 0.92 } }

local function FindSpec()
    for _, s in ipairs(SPECS) do
        if KnowsSpell(s.id) then return s end
    end
    return PLAIN_MAGE
end

local function GetSpec() return g_Spec or PLAIN_MAGE end

local BORDER = { 0.25, 0.78, 0.92, 0.85 }

local function Hex(c)
    return string.format("%02x%02x%02x",
        math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Appearance()
    local spec = GetSpec()
    local r, g, b = spec.color[1], spec.color[2], spec.color[3]
    return {
        icon       = spec.icon,
        title      = "|cff" .. Hex(spec.color) .. "Buffy|r",
        border     = BORDER,
        header     = { 0.03 + r * 0.20, 0.05 + g * 0.10, 0.10 + b * 0.08, 0.98 },
        headerLine = { r, g, b, 0.70 },
        footerLine = { r, g, b, 0.40 },
    }
end

local ARCANE_POWDER = 17020

RefreshDerived = function()
    g_Spec = FindSpec()
end

local function FooterItems()
    local items = {}
    if B.IsBuffEnabled and not B.IsBuffEnabled("intellect") then return items end
    if INTELLECT.hasGroup then
        items[#items + 1] = {
            itemID = ARCANE_POWDER, icon = ItemIcon(ARCANE_POWDER), usedBy = INTELLECT.grp,
            color = function(count)
                if count >= 50 then return 0.20, 1.00, 0.20 end
                if count >= 25 then return 1.00, 0.88, 0.10 end
                return 1.00, 0.22, 0.10
            end,
        }
    end
    return items
end

C.appearance, C.footerItems, C.refresh = Appearance, FooterItems, RefreshDerived
C.restock = {
    enabledKey = "autoBuyPowder", targetKey = "powderTarget",
    label = "Buy Arcane Powder at vendors", targetLabel = "Arcane Powder target",
    items = function()
        if B.IsBuffEnabled("intellect") and INTELLECT.hasGroup then return { ARCANE_POWDER } end
        return {}
    end,
    names = { [ARCANE_POWDER] = "Arcane Powder" },
}
C.previewFooterItems = function()
    return { { itemID = ARCANE_POWDER, icon = ItemIcon(ARCANE_POWDER), usedBy = INTELLECT.grp } }
end
C.icon = MAGE_ICON
C.enabledKeys = { intellect = "trackIntellect", amplify = "trackAmplify", dampen = "trackDampen" }
C.modeKeys = { amplify = "amplifyMode", dampen = "dampenMode" }
C.reopenForAura = true
local INSTANCE_DB = {
    { "The Barrow Deeps", "Raids", false, false,
      "10 player. NEW in Forever. Encounters are not catalogued yet." },
    { "Hyjal Summit",     "Raids", false, false,
      "20 player. NEW in Forever. Encounters are not catalogued yet. Note this is Forever's own "
      .. "raid, not the TBC one of the same name." },
    { "Onyxia's Lair",    "Raids", false, true,
      "40 player. Breath and Fireball: heavy Fire damage, so Dampen is commonly preferred." },

    { "Ragefire Chasm",   "Dungeons", true, false,
      "Levels 13-18. Mostly physical; Jergosh the Invoker casts Shadow Bolt. Amplify is usually "
      .. "safe." },
    { "The Hall of Thanes", "Dungeons", false, false,
      "Levels 13-18. NEW in Forever. Encounters are not catalogued yet." },
    { "Ruins of Lordaeron", "Dungeons", false, false,
      "Levels 15-20. NEW in Forever. Encounters are not catalogued yet." },
    { "Wailing Caverns",  "Dungeons", false, true,
      "Levels 15-25. Nature damage from the Druids of the Fang throughout; Dampen helps." },
    { "The Deadmines",    "Dungeons", true, false,
      "Levels 18-23. Primarily physical, with some Fire. Amplify is usually fine." },
    { "Shadowfang Keep",  "Dungeons", true, false,
      "Levels 22-30. Arugal and shadow casters, but usually fine for Amplify in level-appropriate "
      .. "groups." },
    { "The Stockade",     "Dungeons", true, false,
      "Levels 22-30. Primarily physical damage; Amplify is usually fine." },
    { "Excavation Site: Wetlands", "Dungeons", false, false,
      "Levels 24-29. NEW in Forever. Encounters are not catalogued yet." },
    { "Blackfathom Deeps", "Dungeons", false, true,
      "Levels 24-32. Nature and Frost casters, and Twilight Lord Kelris' Mind Blast; Dampen "
      .. "helps." },
    { "City of Dalaran",  "Dungeons", false, false,
      "Levels 28-33. NEW in Forever. Encounters are not catalogued yet." },
    { "Scarlet Monastery", "Dungeons", true, false,
      "Levels 28-45, all four wings. The Armory and Cathedral are physical; the Graveyard has "
      .. "shadow casters. Amplify suits most runs." },
    { "Gnomeregan",       "Dungeons", false, true,
      "Levels 29-38. Nature, Fire and mechanical damage; Dampen is often worth it." },
    { "Razorfen Kraul",   "Dungeons", false, true,
      "Levels 30-40. Nature and poison casters throughout; Dampen helps." },
    { "The Drowned City", "Dungeons", false, false,
      "Levels 35-40. NEW in Forever. Encounters are not catalogued yet." },
    { "Krol'Dok Stronghold", "Dungeons", false, false,
      "Levels 40-45. NEW in Forever. Encounters are not catalogued yet." },
    { "Razorfen Downs",   "Dungeons", true, false,
      "Levels 40-50. Amplify is usually fine; Amnennar deals Shadow and Frost damage at the end." },
    { "Uldaman",          "Dungeons", true, false,
      "Levels 42-52. Primarily physical, with some Nature and Arcane. Amplify is usually fine." },
    { "Zul'Farrak",       "Dungeons", false, true,
      "Levels 44-54. Witch Doctor Zum'rah and Nature casters; Dampen helps." },
    { "Maraudon",         "Dungeons", true, false,
      "Levels 45-57, all entrances. Amplify is usually fine." },
    { "Alcaz Prison",     "Dungeons", false, false,
      "Levels 48-53. NEW in Forever. Encounters are not catalogued yet." },
    { "The Temple of Atal'Hakkar", "Dungeons", false, true,
      "Levels 50-60. Magic damage spikes (Shade of Eranikus, Jammal'an); Dampen is favoured. "
      .. "Known to players as the Sunken Temple." },
    { "Blackrock Depths", "Dungeons", true, false,
      "Levels 52-60. Situational; Amplify in the low-pressure sections." },
    { "Blackrock Spire",  "Dungeons", true, false,
      "Levels 55-60, Lower and Upper. Amplify is often acceptable." },
    { "Blackmaw Hold",    "Dungeons", false, false,
      "Levels 55-60. NEW in Forever. Encounters are not catalogued yet." },
    { "Dire Maul",        "Dungeons", true, false,
      "Levels 58-60, all wings. Amplify is often fine outside caster-heavy pulls." },
    { "Scholomance",      "Dungeons", false, true,
      "Levels 58-60. Caster-heavy pulls; Dampen recommended." },
    { "Stratholme",       "Dungeons", false, true,
      "Levels 58-60, both sides. Frequent magic damage favours Dampen." },
    { "Shaper's Terrace", "Dungeons", false, false,
      "Levels 58-60. NEW in Forever. Encounters are not catalogued yet." },
}
C.instances = INSTANCE_DB
