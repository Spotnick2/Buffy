local H = dofile("tests/harness.lua")

local priest = H.load("PRIEST")
priest.SetConfig("showSolo", true)
priest.SetConfig("trackFort", false)
priest.SetConfig("trackSpirit", false)
WoW.flushTimers()
H.eq(priest.ui:IsVisible(), false, "Priest hidden with only undetected Shadow Protection")
WoW.SetAura("player", "Shadow Protection", 600, 600)
WoW.dispatch("UNIT_AURA", "player")
WoW.flushTimers()
H.eq(priest.ui:IsVisible(), true, "Priest reopens when Shadow Protection appears")
priest.ui:Close(true)
WoW.dispatch("UNIT_AURA", "player")
WoW.flushTimers()
H.eq(priest.ui:IsVisible(), false, "detected aura respects manual close")

local mage = H.load("MAGE")
mage.SetConfig("showSolo", true)
mage.SetConfig("trackIntellect", false)
mage.SetConfig("trackDampen", false)
WoW.flushTimers()
H.eq(mage.ui:IsVisible(), false, "Mage hidden with only undetected Amplify Magic")
WoW.inCombat = true
WoW.auraReadsThrow = true
WoW.SetAura("player", "Amplify Magic", 600, 600)
WoW.dispatch("UNIT_AURA", "player")
WoW.flushTimers()
H.eq(mage.ui:IsVisible(), false, "Mage stays hidden while combat blocks aura reads")
WoW.auraReadsThrow = false
WoW.inCombat = false
WoW.dispatch("PLAYER_REGEN_ENABLED")
WoW.flushTimers()
H.eq(mage.ui:IsVisible(), true, "Mage reopens for aura added during combat")
H.eq(#WoW.combatWrites, 0, "detect visibility causes no secure writes in combat")

H.done("detect visibility")
