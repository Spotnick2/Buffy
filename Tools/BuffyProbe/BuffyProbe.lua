-- BuffyProbe: the in-game check of a library pin, as a ForeverProbe module.
--
--   /fp bf state          versions: client, Buffy, the running LibGroupBuffs and LibGlass copies
--   /fp bf spells         Buffy's spell report: every buff name, where it came from, the counts
--   /fp steps bf pin      the guided check of a library pin (Buffy #35: LibGroupBuffs r34)
--
-- Read-only towards Buffy, apart from the /buffy commands a step runs on the owner's click
-- (help, show, test 5|8|off): the same commands the owner would type. It never touches
-- Buffy's saved settings.

local ADDON, NS = ...
local MAX_LOG = 3000

-- What this deploy is meant to run. A newer copy loaded by another addon wins through
-- LibStub, so the checks are "at least".
local EXPECT = { gb = 34, glass = 13 }
local HOSTS = { "Priestly", "Wildly", "Magely" }

local Probe = ForeverProbe:Module("BuffyProbe", { api = 1, cmd = "bf" })
local function say(msg) Probe:Say(msg) end
local show = Probe.Show

local function buffy() return rawget(_G, "Buffy") end

local function lib(major)
    local LS = rawget(_G, "LibStub")
    if type(LS) ~= "table" then return nil end
    return LS(major, true)
end

local function addonInfo(name)
    local C = rawget(_G, "C_AddOns")
    if type(C) ~= "table" then return nil end
    local okL, loaded = Probe:Try(name .. " loaded", C.IsAddOnLoaded, name)
    local okV, version = Probe:Try(name .. " version", C.GetAddOnMetadata, name, "Version")
    return okL and loaded or false, okV and version or nil
end

-- ─── measurements ───────────────────────────────────────────────────────────

local function state()
    local version, build = GetBuildInfo()
    local B = buffy()
    local gb, gbMinor = lib("LibGroupBuffs-1.0")
    local _, glassMinor = lib("LibGlass-1.0")
    local _, buffyVersion = addonInfo("Buffy")
    local out = {
        build = build, buffy = buffyVersion, class = B and B.classToken,
        gb = gbMinor, gbReady = gb and gb.ready, glass = glassMinor,
    }
    say("client " .. show(version, true) .. "." .. show(build, true) .. ", Buffy " .. show(buffyVersion)
        .. ", class " .. show(out.class))
    say("LibGroupBuffs minor " .. show(gbMinor) .. " (ready " .. show(out.gbReady) .. "), LibGlass minor "
        .. show(glassMinor) .. "; expected at least r" .. EXPECT.gb .. " and r" .. EXPECT.glass)
    for _, name in ipairs(HOSTS) do
        local loaded, v = addonInfo(name)
        out[name] = loaded and (v or "loaded") or false
        say(name .. ": " .. (loaded and ("loaded, " .. show(v)) or "not loaded"))
    end
    return out
end

local function stateOK(s)
    s = s or state()
    local ok = type(s.gb) == "number" and s.gb >= EXPECT.gb and s.gbReady == s.gb
        and type(s.glass) == "number" and s.glass >= EXPECT.glass
    return ok, "LibGroupBuffs " .. show(s.gb) .. " ready " .. show(s.gbReady) .. ", LibGlass " .. show(s.glass)
end

local function spells()
    local B = buffy()
    if not (B and B.engine) then say("spells: Buffy has no engine (unsupported class, or not logged in)"); return nil end
    local ok, report = Probe:Try("SpellReport", B.engine.SpellReport, B.engine)
    if not ok or type(report) ~= "table" then return nil end
    local forms, learned = 0, 0
    for _, entry in ipairs(report) do
        for _, form in ipairs(entry.forms or {}) do
            forms = forms + 1
            if form.known then learned = learned + 1 end
            if form.from == "fallback" or form.from == "unknown" then
                say("  " .. show(entry.id, true) .. " " .. show(form.role, true) .. ": " .. show(form.name)
                    .. " from " .. show(form.from))
            end
        end
    end
    local r = {
        class = B.classToken, locale = report.locale, buffs = #report, forms = forms, learned = learned,
        unresolved = report.unresolved or 0, unknown = report.unknown or 0, ranks = #(report.ranks or {}),
    }
    say("spells " .. show(r.class, true) .. " (" .. show(r.locale, true) .. "): " .. r.buffs .. " buffs, "
        .. r.forms .. " names, " .. r.learned .. " learned; unresolved " .. r.unresolved .. ", unknown "
        .. r.unknown .. ", unreadable ranks " .. r.ranks)
    return r
end

local function spellsOK(r)
    if not r then return false, "no report" end
    return r.unresolved == 0 and r.unknown == 0,
        "unresolved " .. r.unresolved .. ", unknown " .. r.unknown .. ", class " .. show(r.class, true)
end

-- A /buffy command, as typed. Returns the window's state after it.
local function buffyCmd(arg)
    local slash = rawget(_G, "SlashCmdList") and SlashCmdList.BUFFY
    local ok = Probe:Try("/buffy " .. arg, slash, arg)
    local B = buffy()
    local visible = B and B.ui and B.ui:IsVisible()
    local grow = B and B.Get and B.Get("growDirection")
    say("/buffy " .. arg .. ": " .. (ok and "ran" or "FAILED") .. "; visible " .. show(visible)
        .. ", preview " .. show(B and B.previewActive) .. ", growth " .. show(grow))
    return ok, visible, B and B.previewActive or false, grow
end

-- The player's successful casts, counted (spell ids only).
local casts, lastCast, armedAt = 0, nil, nil
local castWatch = CreateFrame("Frame")
if not Probe:Try("UNIT_SPELLCAST_SUCCEEDED (player)", castWatch.RegisterUnitEvent, castWatch,
        "UNIT_SPELLCAST_SUCCEEDED", "player") then
    Probe:RegisterEvents(castWatch, { "UNIT_SPELLCAST_SUCCEEDED" })
end
castWatch:SetScript("OnEvent", function(_, _, unit, _, spellID)
    if unit ~= "player" then return end
    casts = casts + 1
    local ok, name = Probe:Try("GetSpellInfo", rawget(_G, "GetSpellInfo"), spellID)
    lastCast = { id = spellID, name = ok and name or nil }
end)

local function combatState()
    local f = rawget(_G, "InCombatLockdown")
    return type(f) == "function" and f() or false
end

-- ─── commands ───────────────────────────────────────────────────────────────

Probe:Command("state", function() stateOK(state()) end, "client, Buffy and the running library copies")
Probe:Command("spells", function() spells() end, "Buffy's spell report and its counts")
Probe:Command("clear", function() Probe:ClearLog(); say("log cleared") end, "empty the saved log")

-- ─── the procedure ──────────────────────────────────────────────────────────

Probe:Steps("pin", {
    rev = 1,
    title = "Buffy on its library pin (#35)",
    { text = "Out of combat, on a Priest, Druid or Mage. Type /console scriptErrors 1 once, then press Next." },
    { text = "Reading the versions: client, Buffy, and the LibGroupBuffs and LibGlass copies running.",
      auto = true,
      run = function()
          local s = state()
          if type(BuffyProbeDB) == "table" then BuffyProbeDB.firstClass = s.class end
          return s.build, s.buffy, s.class, s.gb, s.glass
      end,
      check = function() return stateOK() end },
    { text = "No Lua error since login or /reload (BugSack, or the error window)?", ask = true },
    { text = "Run /buffy help. It prints in chat and ends with the spell list.", button = "Run /buffy help",
      screenshot = "buffy help",
      run = function() local ok = buffyCmd("help"); local r = spells(); return ok, r and r.unresolved, r and r.unknown end,
      check = function()
          local ok, detail = spellsOK(spells())
          return ok, detail
      end },
    { text = "Open the window.", button = "Open", run = function() return buffyCmd("show") end },
    { text = "Drag the window somewhere else, minimize it, then restore it. All normal?", ask = true,
      screenshot = "window moved and restored" },
    { text = "Show the 5-member preview.", button = "/buffy test 5", screenshot = "preview 5",
      run = function() return buffyCmd("test 5") end,
      check = function() local B = buffy(); return B and B.previewActive == true, "preview " .. show(B and B.previewActive) end },
    { text = "Show the 8-member preview.", button = "/buffy test 8", screenshot = "preview 8",
      run = function() return buffyCmd("test 8") end },
    { text = "Rows, icons and timers look as before?", ask = true },
    { text = "In /buffy config, switch Window growth to the other direction. The rows grow the other way? "
          .. "Switch it back afterwards.", ask = true, screenshot = "growth flipped" },
    { text = "End the preview.", button = "/buffy test off",
      run = function() return buffyCmd("test off") end,
      check = function() local B = buffy(); return B and not B.previewActive, "preview " .. show(B and B.previewActive) end },
    { text = "Get ready to cast: someone in your group (or you alone) should be missing one of your buffs. "
          .. "Press Arm, then click that buff's button in Buffy's window.", button = "Arm",
      run = function() armedAt = casts; return casts end },
    { text = "Click a buff button in Buffy's window now.", timeout = 180,
      wait = function()
          if not armedAt then armedAt = casts end
          if casts > armedAt then return true, lastCast and lastCast.id, lastCast and lastCast.name end
          return false, "no cast yet"
      end },
    { text = "Did it land on the member you clicked (or on you, if it was yours)?", ask = true },
    { text = "Hover a buff row so its tooltip shows, and type /fp shot tooltip without moving the mouse. "
          .. "Tooltip and timer colours right (green over 50%, yellow 10-50%, red under 10%)?", ask = true },
    { text = "With the window open, enter combat (a training dummy or a mob).", timeout = 600,
      wait = function() if combatState() then return true end; return false, "not in combat yet" end },
    { text = "In combat: try close and minimize. Do they behave as before (no blocked-action error)?",
      ask = true },
    { text = "Leave combat.", timeout = 600,
      wait = function() if not combatState() then return true end; return false, "still in combat" end },
    { text = "Out of combat, the window settled (no stuck rows, no error)?", ask = true,
      screenshot = "after combat" },
    { text = "Optional, skip if you can't today: in a battleground, are the ? marks like on r33?",
      ask = true, screenshot = "battleground" },
    { text = "Open a vendor (a reagent vendor if you have one).", event = "MERCHANT_SHOW" },
    { text = "Restock and the reagent footer behave as in beta1?", ask = true, screenshot = "vendor" },
    { text = "Log out, then log in on another supported class (Druid or Mage if you were a Priest). "
          .. "The procedure comes back after the login. Then press Next." },
    { text = "Reading the spell report on this class.", auto = true,
      run = function()
          local r = spells()
          local s = state()
          return s.class, r and r.unresolved, r and r.unknown
      end,
      check = function()
          local r = spells()
          local first = type(BuffyProbeDB) == "table" and BuffyProbeDB.firstClass
          local ok, detail = spellsOK(r)
          return ok and r.class ~= first, detail .. ", first class " .. show(first, true)
      end },
    { text = "Type /reload (or press Reload now) to save the results.", reload = true },
})

-- ─── boot ───────────────────────────────────────────────────────────────────

local boot = CreateFrame("Frame")
Probe:RegisterEvents(boot, { "ADDON_LOADED" })
boot:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    Probe:Ready()
    if type(BuffyProbeDB) ~= "table" then BuffyProbeDB = {} end
    if type(BuffyProbeDB.log) ~= "table" then BuffyProbeDB.log = {} end
    Probe:UseLog(BuffyProbeDB.log, MAX_LOG)
    BuffyProbeDB.loads = (BuffyProbeDB.loads or 0) + 1
    say("loaded (" .. BuffyProbeDB.loads .. " loads). /fp bf for the commands; /fp steps bf pin")
end)

NS._test = { Probe = Probe, state = state, stateOK = stateOK, spells = spells, spellsOK = spellsOK }
