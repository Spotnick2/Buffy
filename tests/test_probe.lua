-- BuffyProbe, the ForeverProbe module behind the in-game pin check (#35).
-- ForeverProbe is private and local only: CI sets FOREVERPROBE_OPTIONAL=1 and
-- this file skips there (ForeverProbe docs/GUIDE.md, section 8).
local H = dofile("tests/harness.lua")

local root = (os.getenv("FOREVERPROBE") or "../ForeverProbe"):gsub("\\", "/"):gsub("/$", "")
local toc = io.open(root .. "/ForeverProbe.toc", "rb")
if not toc then
    if os.getenv("FOREVERPROBE_OPTIONAL") == "1" then
        io.write("SKIPPED: ForeverProbe isn't here (private, local only); the probe tests run locally\n")
        os.exit(0)
    end
    error("ForeverProbe checkout not found at " .. root .. ": clone it there or set FOREVERPROBE", 0)
end
local hostFiles = {}
for line in toc:read("*a"):gmatch("[^\r\n]+") do
    if line:match("%.lua$") and not line:match("^#") then hostFiles[#hostFiles + 1] = root .. "/" .. line end
end
toc:close()

-- Buffy logs in first; the host and the probe load after, as LibGroupBuffs'
-- probe test does, so the host's console (built at PLAYER_LOGIN) stays out of
-- the strict stub.
local ns = {}
H.load("PRIEST")
WoW.allowGlobal("ForeverProbe", "ForeverProbeDB", "BuffyProbeDB", "SLASH_FOREVERPROBE1", "SLASH_FOREVERPROBE2")
WoW.allowMethod("RegisterUnitEvent")   -- SimpleFrameAPI in forever-api-1.60.1.70959.md
for _, file in ipairs(hostFiles) do assert(loadfile(file))("ForeverProbe", {}) end
WoW.dispatch("ADDON_LOADED", "ForeverProbe")
assert(loadfile("Tools/BuffyProbe/BuffyProbe.lua"))("BuffyProbe", ns)
WoW.dispatch("ADDON_LOADED", "BuffyProbe")
local T = ns._test
H.check(T ~= nil, "the probe exposes its test seam")
H.check(type(BuffyProbeDB) == "table" and type(BuffyProbeDB.log) == "table", "saved table adopted at ADDON_LOADED")

-- The versions: the library copies the harness loaded. Every probe line goes
-- to the console and the saved log, none to chat. (/fp bf state would open the
-- console, whose widgets the shared stub doesn't model, so the functions behind
-- the commands are called directly.)
local before = #WoW.messages
local s = T.state()
local _, gbMinor = LibStub("LibGroupBuffs-1.0")
local _, glassMinor = LibStub("LibGlass-1.0")
H.eq(s.gb, gbMinor, "LibGroupBuffs minor read through LibStub")
H.eq(s.glass, glassMinor, "LibGlass minor read through LibStub")
H.eq(s.class, "PRIEST", "class token")
H.eq(T.stateOK(s), gbMinor >= 34 and glassMinor >= 13, "the pin check follows the loaded minors")

-- The spell report: every priest name resolved from the client in the harness.
local r = T.spells()
H.check(r ~= nil and r.buffs > 0 and r.forms >= r.buffs, "spell report counted")
H.eq(r and r.class, "PRIEST", "report class")
H.eq((T.spellsOK(r)), true, "no fallback or unknown names")
H.eq((T.spellsOK(nil)), false, "no report is a FAIL")
H.eq((T.spellsOK({ unresolved = 1, unknown = 0, class = "PRIEST" })), false, "a fallback name is a FAIL")
H.eq((T.spellsOK({ unresolved = 0, unknown = 2, class = "PRIEST" })), false, "an unknown name is a FAIL")

H.eq(#WoW.messages, before, "probe lines stay out of chat")
local logged = table.concat(BuffyProbeDB.log, "\n")
H.check(logged:find("LibGroupBuffs minor", 1, true) ~= nil, "state is in the saved log")
H.check(logged:find("spells PRIEST", 1, true) ~= nil, "the report is in the saved log")

-- The procedure is registered under the module.
H.check(ForeverProbe.procedures["BuffyProbe/pin"] ~= nil, "the pin procedure is defined")

-- The player's casts: counted, named through Buffy's adapter (the global
-- GetSpellInfo is gone on Forever), and another unit's cast ignored (Codex, #45).
local spellID = Buffy.class.defs[1].snglID
local logBefore = #BuffyProbeDB.log
WoW.dispatch("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-1", spellID)
H.eq((T.casts()), 0, "another unit's cast is not counted")
WoW.dispatch("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", spellID)
local n, last = T.casts()
H.eq(n, 1, "the player's cast is counted")
H.eq(last and last.id, spellID, "cast spell id")
H.eq(last and last.name, Buffy.API.SpellName(spellID), "cast named through Buffy.API.SpellName")
H.check(last and last.name ~= nil, "the cast has a name")
local newLines = table.concat(BuffyProbeDB.log, "\n", logBefore + 1)
H.check(not newLines:find("MISSING", 1, true), "no MISSING diagnostic on a cast")

-- Through the procedure: a /buffy command that throws fails its step. The run
-- errors, the step stays for Retry, and it neither completes nor passes its
-- check (Codex, #45). The panel isn't built here: the shared stub doesn't model
-- its widgets, so Show and Refresh are no-ops for this test.
local FP = ForeverProbe
FP.Steps.Show, FP.Steps.Refresh = function() end, function() end
local handled = {}
WoW.allowGlobal("geterrorhandler")         -- a client global the shared stub leaves out
local realHandler = rawget(_G, "geterrorhandler")
geterrorhandler = function() return function(e) handled[#handled + 1] = e end end
H.check(T.Probe:StartSteps("pin"), "the procedure starts")
local rec = ForeverProbeDB.steps.records["BuffyProbe/pin"]
FP.Steps.Next()                                  -- 1: the setup step; 2 runs on arrival
H.eq(rec.results[2] and rec.results[2].check, gbMinor >= 34 and glassMinor >= 13 and "PASS" or "FAIL",
    "step 2's check follows the loaded minors")
H.eq(rec.at, 3, "on /buffy help (no Lua-error question: Bugsy is read instead)")
local realSlash = SlashCmdList.BUFFY
SlashCmdList.BUFFY = function() error("boom from /buffy", 0) end
FP.Steps.Run()
local r3 = rec.results[3] or {}
H.eq(rec.at, 3, "a throwing command keeps the step")
H.eq(r3.errors, 1, "the error is counted on the step")
H.check(r3.status == nil and r3.check == nil, "the step neither completed nor ran its check")
H.check(tostring(r3.lastError):find("boom from /buffy", 1, true) ~= nil, "the command's error is recorded")
H.eq(#handled, 1, "the error reached the error handler")
H.check(table.concat(BuffyProbeDB.log, "\n"):find("/buffy help: ERROR", 1, true) ~= nil, "the failure is logged")
SlashCmdList.BUFFY = nil                         -- a missing handler fails the same way
FP.Steps.Run()
H.eq(rec.at, 3, "a missing command keeps the step")
H.eq((rec.results[3] or {}).errors, 2, "and counts as an error")
SlashCmdList.BUFFY = realSlash
FP.Steps.Stop("test over")
rawset(_G, "geterrorhandler", realHandler)

H.done("probe")
