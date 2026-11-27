local H = dofile("tests/harness.lua")
local B = H.load("PRIEST")
B.SetConfig("trackFort", false)
B.SetConfig("showReagents", false)
B.SetConfig("autoBuyCandles", true)
B.SetConfig("candleTarget", 120)
B.SetWindowState("pos", { point = "CENTER", relPoint = "CENTER", x = 10, y = 20 })
B.SetWindowState("visible", false)
H.eq(BuffyDB.visible, false, "character visibility")
H.eq(B.Profile().pos, nil, "position not account-wide")
H.eq(BuffyDB.trackFort, nil, "config not per-character")
B.LearnDuration("Test", 123)
H.eq(B.LearnedDuration("Test"), 123, "learned duration")
B.LearnDuration("Test", 60)
H.eq(B.LearnedDuration("Test"), 60, "duration may decrease")
local account = BuffyAccountDB
B = H.load("PRIEST", nil, function() BuffyAccountDB = account end)
H.eq(B.Get("trackFort"), false, "profile shared by priests")
H.eq(B.Get("showReagents"), false, "footer preference shared by priests")
H.eq(B.Get("autoBuyCandles"), true, "Priest restock preference shared")
H.eq(B.Get("candleTarget"), 120, "Priest restock target shared")
H.eq(B.WindowState("pos"), nil, "new character starts unpositioned")
B = H.load("MAGE", nil, function() BuffyAccountDB = account end)
H.eq(B.Get("trackIntellect"), true, "mage defaults independent")
H.eq(B.Get("showReagents"), true, "mage footer preference independent")
H.eq(B.Get("autoBuyPowder"), false, "Mage restock disabled independently")
H.eq(B.Get("powderTarget"), 80, "Mage target independent")
H.eq(B.LearnedDuration("Test"), nil, "duration isolated by class")
H.eq(account.classes.PRIEST.trackFort, false, "priest profile preserved")
H.eq(B.Get("amplifyMode"), "detect", "mage mode default")
B.SetConfig("amplifyMode", "always")
H.eq(B.Get("dampenMode"), "detect", "independent mage modes")
B = H.load("DRUID", nil, function()
    BuffyAccountDB = { classes = { DRUID = { thornsMode = "invalid", frameScale = 99,
        frameAlpha = 0/0, growDirection = "sideways", giftTarget = 0 } } }
end)
H.eq(B.Get("thornsMode"), "default", "invalid thorns repaired")
H.eq(B.Get("frameScale"), 1, "invalid scale repaired")
H.eq(B.Get("frameAlpha"), 0.96, "NaN alpha repaired")
H.eq(B.Get("growDirection"), "down", "invalid growth direction repaired")
H.eq(B.Get("autoBuyGift"), false, "Druid restock disabled independently")
H.eq(B.Get("giftTarget"), 80, "invalid Gift target repaired")

-- #72: no build is announced or recorded, not even by a development copy (the unpackaged
-- TOC's version token). The stub's build (WoW.build) is not the library's measuredOnBuild,
-- so the library does report newBuild.
local function printed(pattern)
    for _, line in ipairs(WoW.messages) do if line:find(pattern) then return line end end
end
B = H.load("PRIEST", nil, function()
    BuffyAccountDB = { seenBuild = "69977", classes = {} }
    C_AddOns.GetAddOnMetadata = function(_, key)
        if key == "Version" then return "@" .. "project-version@" end
    end
end)
H.eq(B.API.AddonVersion("Buffy"), "@" .. "project-version@", "a development copy")
H.eq(BuffyAccountDB.seenBuild, nil, "the old seenBuild is deleted")
WoW.dispatch("PLAYER_ENTERING_WORLD", true, false)
WoW.dispatch("PLAYER_ENTERING_WORLD", false, true)
H.eq(printed("[Bb]uild"), nil, "a development copy's login and reload print no build line")
H.eq(BuffyAccountDB.seenBuild, nil, "no build is recorded")

-- Learned durations last until an Interface bump, not a build.
local function withClient(build, interface)
    return function()
        BuffyAccountDB = account
        WoW.build = build
        GetBuildInfo = function() return "1.60.1", build, "Nov 26 2026", interface end
    end
end
B = H.load("PRIEST", nil, withClient("71037", 16001))
B.LearnDuration("Test", 1800)
H.eq(account.classes.PRIEST.learnedDurations.interface, 16001, "durations keyed by the Interface")
H.eq(account.classes.PRIEST.learnedDurations.build, nil, "not by the build")
B = H.load("PRIEST", nil, withClient("71139", 16001))
H.eq(B.LearnedDuration("Test"), 1800, "a new build keeps the learned durations")
B = H.load("PRIEST", nil, withClient("71200", 16002))
H.eq(B.LearnedDuration("Test"), nil, "a new Interface discards them")
B.LearnDuration("Test", 1200)
H.eq(account.classes.PRIEST.learnedDurations.interface, 16002, "relearned under the new Interface")
account.classes.PRIEST.learnedDurations = { build = "71037", Test = 1800 }
B = H.load("PRIEST", nil, withClient("71037", 16001))
H.eq(B.LearnedDuration("Test"), nil, "a store keyed by build (before #72) is relearned once")
H.done("config")
