local H = dofile("tests/harness.lua")
local reported, wanted, tint, preset = nil, true, "smoked", "pearl"
local suite = {
    API = 1,
    Theme = function() return wanted and { preset = preset } or nil end,
    Look = function() return { tint = tint, accent = "ice" } end,
    Body = function()
        if tint == "class" then return { classShade = 0.6, wash = 1, backing = { 0.04, 0.05, 0.07, 0.35 } } end
        return { tint = { 0.05, 0.06, 0.08, 0.62 }, wash = 0.14/0.18, backing = { 0.04, 0.05, 0.07, 0.92 } }
    end,
    Accent = function() return { 0.65, 0.835, 0.905 } end,
    Report = function(name, state) H.eq(name, "Buffy", "suite report owner"); reported = state end,
}
local B = H.load("PRIEST", suite)
B.SetConfig("showSolo", true)
WoW.flushTimers()
H.check(B.FollowingSuite(), "valid suite followed")
H.eq(reported.built, "pearl", "built material")
H.eq(reported.live, false, "reload required")
H.eq(reported.look.tint, "smoked", "effective tint")
H.eq(reported.look.accent, "ice", "effective accent")
H.eq(type(reported.options), "function", "options callback")
local g = B.ui.main.glass
H.near(g.tint._colorTexture[4], 0.62, "suite opacity")
H.near(g.bodyBacking._colorTexture[4], 0.92, "masked backing")
H.near(g.wash.glassPeak, B.Material().STYLE.wash * 0.14/0.18, "wash multiplier")
B.SetConfig("frameAlpha", 0.2)
H.near(g.tint._colorTexture[4], 0.62, "local opacity suspended")
H.near(B.Get("frameAlpha"), 0.2, "local opacity retained")
B.optionsPanel:GetScript("OnShow")(B.optionsPanel)
B.optionsPanel.controls.frameAlpha:GetScript("OnValueChanged")(B.optionsPanel.controls.frameAlpha, 0.9)
H.near(B.Get("frameAlpha"), 0.2, "disabled opacity control cannot write")
reported.options()
local ownGlass = B.Material()
local lib = LibStub("LibGroupBuffs-1.0")
local old = lib:New({ owner = "OriginalAddon", needs = 31, report = function() end })
local otherEngine = old.Engine({ defs = { { id = "fort", snglID = 1243, sngl = "Power Word: Fortitude", duration = 60 } },
    bucketSize = 8, showSolo = function() return true end })
otherEngine:RefreshSpells()
local otherUI = old.UI({ engine = otherEngine })
otherUI:Init()
H.check(lib.glass ~= ownGlass, "original uses a separate shared material")
H.eq(otherUI.main.glass.bodyBacking, nil, "original has no suite backing")
H.near(otherUI.main.glass.tint._colorTexture[4], 0.24 * 0.96, "original opacity preserved")
H.near(B.ui.main.glass.tint._colorTexture[4], 0.62, "original construction leaves Buffy intact")
tint = "class"
B = H.load("MAGE", suite)
H.check(B.FollowingSuite(), "class tint accepted")
H.near(B.BodyStyle().tint[1], RAID_CLASS_COLORS.MAGE.r * 0.6, "class tint shade")
wanted = false
B = H.load("DRUID", suite)
H.eq(B.FollowingSuite(), false, "follow off uses Clean")
H.eq(reported.built, nil, "no claimed suite material")
H.eq(B.ui.main.glass.bodyBacking, nil, "standalone no backing")
wanted, preset = true, "nonexistent-preset"
B = H.load("PRIEST", suite)
H.eq(B.FollowingSuite(), false, "failed material fallback")
H.eq(reported.reason, "build-failed", "failure accurately reported")
H.check(B.ui.main ~= nil, "failed suite material still usable")
preset = "pearl"
suite.Body = function() return { wash = 0/0, tint = {} } end
B = H.load("PRIEST", suite)
H.eq(B.FollowingSuite(), false, "malformed body rejected")
suite.Theme = function() error("broken contract") end
B = H.load("MAGE", suite)
H.eq(B.FollowingSuite(), false, "throwing suite ignored safely")
suite.API = 2
B = H.load("DRUID", suite)
H.eq(B.FollowingSuite(), false, "incompatible suite ignored")
H.done("appearance")
