local H = dofile("tests/harness.lua")
local B = H.load("DRUID")
local members = { { unit = "player", class = "DRUID" }, { unit = "party1", class = "WARRIOR" },
    { unit = "partypet1", class = "PET_HUNTER" } }
WoW.SetUnit("party1", { class = "WARRIOR", role = "TANK" })
WoW.groupMembers = 2
local def = B.class.defs[2]
B.SetConfig("thornsMode", "everyone")
H.eq(#B.engine:MembersFor(def, members), 3, "everyone thorns includes tracked pets")
B.SetConfig("trackPets", false)
H.eq(#B.engine:MembersFor(def, members), 2, "everyone thorns leaves pets out when pets are not tracked")
B.SetConfig("trackPets", true)
-- Mark/Gift: Forever refuses stat buffs on hunter and warlock pets; other pets keep it.
local mark = B.class.defs[1]
local petMix = { { unit = "player", class = "DRUID" }, { unit = "partypet1", class = "PET_HUNTER" },
    { unit = "partypet2", class = "PET_WARLOCK" }, { unit = "partypet3", class = "PET" } }
local markFor = B.engine:MembersFor(mark, petMix)
H.eq(#markFor, 2, "mark excludes hunter and warlock pets")
H.eq(markFor[2] and markFor[2].class, "PET", "mark keeps other pet types")
B.SetConfig("thornsMode", "self")
H.eq(B.engine:MembersFor(def, members)[1].unit, "player", "self targeting")
B.SetConfig("thornsMode", "tanks")
B.class.forgetRoster()
H.eq(B.engine:MembersFor(def, members)[1].unit, "party1", "tank targeting")
B.SetConfig("thornsMode", "default")
H.eq(B.class.effectiveMode(), "tanks", "automatic targets assigned tanks")
WoW.units.party1.role = "NONE"
WoW.dispatch("PLAYER_ROLES_ASSIGNED")
H.eq(B.class.effectiveMode(), "self", "role change invalidates tank cache")
B.SetConfig("thornsMode", "disabled")
H.eq(B.IsBuffEnabled("thorns"), false, "disabled thorns")

B.SetConfig("thornsMode", "self")
H.eq(#B.engine:MembersFor(def, members), 1, "self thorns never covers pets")
B.SetConfig("thornsMode", "tanks")
WoW.units.party1.role = "TANK"
WoW.dispatch("PLAYER_ROLES_ASSIGNED")
H.eq(#B.engine:MembersFor(def, members), 1, "tank thorns never covers pets")

B = H.load("MAGE")
local intellect, amplify = B.class.defs[1], B.class.defs[2]
local intFor = B.engine:MembersFor(intellect, petMix)
H.eq(#intFor, 2, "intellect excludes hunter and warlock pets")
H.eq(intFor[2] and intFor[2].class, "PET", "intellect keeps other pet types")
H.eq(#B.engine:MembersFor(amplify, petMix), 4, "amplify keeps every pet")

B = H.load("PRIEST")
local fort = B.class.defs[1]
H.eq(#B.engine:MembersFor(fort, members), 2, "fortitude excludes hunter pets")
local shadow = B.class.defs[3]
local groups, ord = { [1] = { { unit = "player", class = "PRIEST" } } }, { 1 }
H.eq(B.IsVisible(shadow, groups, ord), false, "detect hidden without aura")
H.eq(B.Get("shadowInBG"), false, "battleground override defaults off")
WoW.instanceName, WoW.instanceType = "Warsong Gulch", "pvp"
H.eq(B.IsVisible(shadow, groups, ord), false, "battleground retains detect when disabled")
B.SetConfig("shadowInBG", true)
for _, mode in ipairs({ "detect", "instance", "always" }) do
    B.SetConfig("shadowMode", mode)
    H.eq(B.IsVisible(shadow, groups, ord), true, "battleground override in " .. mode)
end
B.SetConfig("shadowMode", "detect")
WoW.instanceType = "arena"
H.eq(B.IsVisible(shadow, groups, ord), false, "arena is separate from battleground")
WoW.instanceType = "none"
H.eq(B.IsVisible(shadow, groups, ord), false, "leaving battleground restores detection")
WoW.SetAura("player", shadow.sngl, 600, 300, shadow.snglID)
H.eq(B.IsVisible(shadow, groups, ord), true, "detect visible with aura")
WoW.locale = "frFR"
WoW.DefineSpell(976, "Protection contre l'ombre")
WoW.Know(976, "Protection contre l'ombre")
WoW.dispatch("SPELLS_CHANGED")
WoW.ClearAuras("player")
WoW.SetAura("player", "Protection contre l'ombre", 600, 300, 976)
H.eq(B.IsVisible(shadow, groups, ord), true, "detect uses localized names")
B.SetConfig("shadowMode", "instance")
WoW.instanceName, WoW.instanceType, WoW.instanceMapID = "Localized Lordaeron", "party", 2999
B.SetInstance("shadow", "Ruins of Lordaeron", true)
H.eq(B.IsVisible(shadow, groups, ord), true, "priest instance map alias")
WoW.instanceType = "none"
H.eq(B.IsVisible(shadow, groups, ord), false, "outdoors is not an instance")
B.SetConfig("shadowMode", "detect")
WoW.inCombat, WoW.secret, WoW.auraReadsThrow = true, true, true
H.eq(B.IsVisible(shadow, groups, ord), true, "blocked aura does not remove row")

B = H.load("MAGE")
local amplify, dampen = B.class.defs[2], B.class.defs[3]
B.SetConfig("amplifyMode", "always")
H.eq(B.IsVisible(amplify, groups, ord), true, "amplify always")
H.eq(B.IsVisible(dampen, groups, ord), false, "dampen independent detect")
B.SetConfig("dampenMode", "instance")
WoW.instanceName, WoW.instanceType = "Onyxia's Lair", "raid"
H.eq(B.IsVisible(dampen, groups, ord), true, "dampen instance default preserved")
B.SetInstance("dampen", "Onyxia's Lair", false)
H.eq(B.IsVisible(dampen, groups, ord), false, "instance opt out")
H.done("classes")
