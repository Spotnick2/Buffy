-- BuffyProbe: the in-game check of a library pin, as a ForeverProbe module.
--
--   /fp bf state          versions: client, Buffy, the running LibGroupBuffs and LibGlass copies
--   /fp bf spells         Buffy's spell report: every buff name, where it came from, the counts
--   /fp steps bf pin      the guided check of a library pin (Buffy #35: LibGroupBuffs r34)
--   /fp bf talents        your talents through the traits system (#52)
--   /fp steps bf cd       what a cooldown pane can read (#52): our own instant casts' spell id in
--                         and out of combat, and the traits tree, ours and an inspected player's
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

-- A /buffy command, as typed. Returns the window's state after it. A command
-- that throws (or is missing) throws here too, after the state is logged, so the
-- step's run fails: ForeverProbe records the error, keeps the step for Retry and
-- hands the error to the error handler (BugSack). A caught error must never let
-- the step complete and its check pass (Codex, #45).
local function buffyCmd(arg)
    local slash = rawget(_G, "SlashCmdList") and SlashCmdList.BUFFY
    local ok, err
    if type(slash) ~= "function" then
        ok, err = false, "SlashCmdList.BUFFY is missing (Buffy not loaded?)"
    else
        ok, err = pcall(slash, arg)
    end
    local B = buffy()
    local visible = B and B.ui and B.ui:IsVisible()
    local grow = B and B.Get and B.Get("growDirection")
    say("/buffy " .. arg .. ": " .. (ok and "ran" or ("ERROR " .. show(err, true))) .. "; visible "
        .. show(visible) .. ", preview " .. show(B and B.previewActive) .. ", growth " .. show(grow))
    if not ok then error(err, 0) end
    return ok, visible, B and B.previewActive or false, grow
end

-- The player's successful casts, counted (spell ids only).
local casts, lastCast, armedAt = 0, nil, nil
local castWatch = CreateFrame("Frame")
-- RegisterUnitEvent returns registered:bool (70959 dump); anything but true falls
-- back to the plain event, filtered on the unit below.
local okUnit, registered = Probe:Try("UNIT_SPELLCAST_SUCCEEDED (player)", castWatch.RegisterUnitEvent, castWatch,
    "UNIT_SPELLCAST_SUCCEEDED", "player")
if not (okUnit and registered == true) then
    Probe:RegisterEvents(castWatch, { "UNIT_SPELLCAST_SUCCEEDED" })
end
local function combatState()
    local f = rawget(_G, "InCombatLockdown")
    return type(f) == "function" and f() or false
end

-- issecretvalue, read through rawget: false when the client (or a stub) lacks it.
local function isSecret(v)
    local f = rawget(_G, "issecretvalue")
    return type(f) == "function" and f(v) and true or false
end

castWatch:SetScript("OnEvent", function(_, _, unit, castGUID, spellID)
    if unit ~= "player" then return end
    casts = casts + 1
    -- #52: whether our own cast's spell id stays readable, in and out of combat. A secret is
    -- never compared or named: SpellName is asked only for a plain id.
    local secretID, secretGUID, combat = isSecret(spellID), isSecret(castGUID), combatState()
    local name
    if not secretID then
        -- The global GetSpellInfo is gone on Forever; Buffy's adapter (LibGroupBuffs'
        -- API.SpellName) reads C_Spell (Codex, #45).
        local B = buffy()
        local spellName = B and B.API and B.API.SpellName
        local ok, n = Probe:Try("SpellName", spellName, spellID)
        name = ok and n or nil
    end
    lastCast = { id = not secretID and spellID or nil, name = name, secretID = secretID,
                 secretGUID = secretGUID, combat = combat, n = casts }
    say("cast #" .. casts .. ": spellID " .. (secretID and "<secret>" or show(spellID)) .. " ("
        .. show(name) .. "), castGUID " .. (secretGUID and "<secret>" or "plain") .. ", combat " .. show(combat))
end)

-- A cast after the step's Arm (or after the step was first polled), optionally in combat.
local function castSince(wantCombat)
    if not armedAt then armedAt = casts end
    if casts > armedAt and lastCast and (wantCombat == nil or lastCast.combat == wantCombat) then
        return true, lastCast.id, lastCast.name, lastCast.secretID, lastCast.combat
    end
    return false, wantCombat and "no cast in combat yet" or "no cast yet"
end

-- ─── #52: the traits tree (who took Power Infusion) ─────────────────────────

-- Classic's ids. Forever re-ids some spells (Mark of the Wild was cast as 1328375 on 70959),
-- so a taken spell also counts as Power Infusion by its name, and the ids the client gives for
-- both names are logged.
local POWER_INFUSION, INNERVATE = 10060, 29166
local PI_NAME = "Power Infusion"

local function spellName(id)
    local B = buffy()
    local f = B and B.API and B.API.SpellName
    local ok, n = Probe:Try("SpellName", f, id)
    return ok and n or nil
end

-- t[k] for a plain table t, else nil. The value may be secret: it is returned as is and never
-- truth-tested here. A truth test (`x and t.k or nil`) on a secret throws on the client, and Lua
-- 5.1 test doubles can't show it (porting guide), so every caller asks isSecret first (Codex, #53).
local function field(t, k)
    if type(t) ~= "table" or isSecret(t) then return nil end
    return t[k]
end

-- The id the client gives for a spell name (C_Spell.GetSpellInfo takes a name too).
local function idForName(name)
    local S = rawget(_G, "C_Spell")
    local ok, info = Probe:Try("C_Spell.GetSpellInfo " .. name, S and S.GetSpellInfo, name)
    if not ok then return nil end
    local id = field(info, "spellID")
    if isSecret(id) then return nil end
    return id
end

-- Walks a talent config's trees: every node, the ones with a rank, and the spell behind each
-- taken entry. Read-only. configID is ours (C_ClassTalents.GetActiveConfigID) or the inspect
-- config. treeIDs default to the config's own (C_Traits.GetConfigInfo); a secret anywhere is
-- counted, never compared.
local lastTraits
local function walkTraits(configID, label, treeIDs)
    local T = rawget(_G, "C_Traits")
    local r = { label = label, config = configID, nodes = 0, ranked = 0, spells = {}, secrets = 0, pi = nil }
    if type(T) ~= "table" then say(label .. ": C_Traits is missing"); lastTraits = r; return r end
    if not treeIDs then
        local ok, info = Probe:Try(label .. " GetConfigInfo", T.GetConfigInfo, configID)
        if ok then
            treeIDs = field(info, "treeIDs")
            if isSecret(treeIDs) then r.secrets = r.secrets + 1; treeIDs = nil end
            local trees = type(treeIDs) == "table" and #treeIDs or nil
            say(label .. ": config " .. show(configID) .. " " .. show(field(info, "name")) .. ", type "
                .. show(field(info, "type")) .. ", trees " .. show(trees))
        end
    end
    if type(treeIDs) ~= "table" or #treeIDs == 0 then
        say(label .. ": no tree for config " .. show(configID)); lastTraits = r; return r
    end
    for _, treeID in ipairs(treeIDs) do
        local okN, nodeIDs = Probe:Try(label .. " GetTreeNodes", T.GetTreeNodes, treeID)
        if not okN or type(nodeIDs) ~= "table" or isSecret(nodeIDs) then nodeIDs = {} end
        for _, nodeID in ipairs(nodeIDs) do
            r.nodes = r.nodes + 1
            local ok, node = Probe:Try(label .. " GetNodeInfo", T.GetNodeInfo, configID, nodeID)
            local rank
            if ok then rank = field(node, "activeRank") end
            if isSecret(rank) then r.secrets = r.secrets + 1
            elseif type(rank) == "number" and rank > 0 then
                r.ranked = r.ranked + 1
                local entryID = field(field(node, "activeEntry"), "entryID")
                local defID, spellID
                if isSecret(entryID) then r.secrets = r.secrets + 1
                else
                    local okE, entry = Probe:Try(label .. " GetEntryInfo", T.GetEntryInfo, configID, entryID)
                    if okE then defID = field(entry, "definitionID") end
                    if isSecret(defID) then r.secrets = r.secrets + 1; defID = nil end
                end
                if defID ~= nil then
                    local okD, def = Probe:Try(label .. " GetDefinitionInfo", T.GetDefinitionInfo, defID)
                    if okD then spellID = field(def, "spellID") end
                end
                if isSecret(spellID) then r.secrets = r.secrets + 1
                elseif type(spellID) == "number" then
                    local name = spellName(spellID)
                    r.spells[#r.spells + 1] = spellID .. "@" .. rank .. (name and ("=" .. name) or "")
                    if spellID == POWER_INFUSION or name == PI_NAME then r.pi = rank; r.piID = spellID end
                end
            end
        end
    end
    say(label .. ": " .. r.nodes .. " nodes, " .. r.ranked .. " with a rank, " .. #r.spells
        .. " spells read, " .. r.secrets .. " secret; Power Infusion " .. (r.pi and ("rank " .. r.pi) or "not taken"))
    if #r.spells > 0 then say(label .. " spells (id@rank=name): " .. table.concat(r.spells, ", ")) end
    lastTraits = r
    return r
end

local function ownTraits()
    local C = rawget(_G, "C_ClassTalents")
    local ok, configID = Probe:Try("GetActiveConfigID", C and C.GetActiveConfigID)
    local known = rawget(_G, "IsPlayerSpell")
    local _, pi = Probe:Try("IsPlayerSpell PI", known, POWER_INFUSION)
    local _, inn = Probe:Try("IsPlayerSpell Innervate", known, INNERVATE)
    local piID, innID = idForName(PI_NAME), idForName("Innervate")
    say("own: Power Infusion known " .. show(pi) .. " (client id by name " .. show(piID) .. "), Innervate known "
        .. show(inn) .. " (client id by name " .. show(innID) .. ")")
    if not ok or isSecret(configID) or configID == nil then say("own: no active config (or a secret one)"); return nil end
    local r = walkTraits(configID, "own")
    r.knowsPI, r.knowsInnervate = pi, inn
    return r
end

-- The inspected player's tree, after INSPECT_READY. The inspect config is
-- Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID on Retail (-1); the dump doesn't list it.
local function inspectConfigID()
    local C = rawget(_G, "Constants")
    local id = type(C) == "table" and type(C.TraitConsts) == "table" and C.TraitConsts.INSPECT_TRAIT_CONFIG_ID
    return id or -1, id and "Constants" or "assumed -1"
end

-- The inspect request and its reply (Codex, #53). INSPECT_READY carries the inspected GUID, and
-- any addon's NotifyInspect fires it, so only the reply for the GUID we asked about counts. Its
-- tree is read in the event handler itself, before a later inspect can replace the client's
-- cached one. The GUID is another player's: it's kept for the match, logged only as a shape.
local inspectWant, inspectGot

local function inspectTraits(guid)
    local id, source = inspectConfigID()
    say("inspect: config " .. show(id) .. " (" .. source .. ")")
    -- The specialization is asked of "target" only while the target is still that player.
    local okG, targetGUID = Probe:Try("UnitGUID target", rawget(_G, "UnitGUID"), "target")
    if okG and not isSecret(targetGUID) and targetGUID == guid then
        local _, specID = Probe:Try("GetInspectSpecialization", rawget(_G, "GetInspectSpecialization"), "target")
        say("inspect: GetInspectSpecialization(target) " .. show(specID))
    else
        say("inspect: the target changed since the request; specialization not asked")
    end
    return walkTraits(id, "inspect")
end

local inspectWatch = CreateFrame("Frame")
Probe:RegisterEvents(inspectWatch, { "INSPECT_READY" })
inspectWatch:SetScript("OnEvent", function(_, _, guid)
    if not inspectWant or inspectGot then return end
    if isSecret(guid) or guid ~= inspectWant then
        say("inspect: a reply for another player (" .. Probe.Shape(guid) .. "), ignored")
        return
    end
    inspectGot = inspectTraits(guid)
end)

-- The Inspect button: the target's GUID is the request. No target (or a secret GUID) fails the
-- step, which stays for Retry or Skip.
local function requestInspect()
    local ok, guid = Probe:Try("UnitGUID target", rawget(_G, "UnitGUID"), "target")
    if not ok or isSecret(guid) or guid == nil then error("no target to inspect (or its GUID is secret)", 0) end
    inspectWant, inspectGot = guid, nil
    say("inspect: requested for the target (" .. Probe.Shape(guid) .. ")")
    local okN = Probe:Try("NotifyInspect", rawget(_G, "NotifyInspect"), "target")
    return okN
end

-- ─── commands ───────────────────────────────────────────────────────────────

Probe:Command("state", function() stateOK(state()) end, "client, Buffy and the running library copies")
Probe:Command("spells", function() spells() end, "Buffy's spell report and its counts")
Probe:Command("talents", function() ownTraits() end, "your talents through the traits system (#52)")
Probe:Command("clear", function() Probe:ClearLog(); say("log cleared") end, "empty the saved log")

-- ─── the procedure ──────────────────────────────────────────────────────────

Probe:Steps("pin", {
    rev = 3,                                   -- 2: a failing /buffy command fails its step; 3: no Lua-error ask
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
    -- No "any Lua error?" question: the session reads Bugsy's SavedVariables (!Bugsy.lua) after
    -- the run, which is what Bugsy is for (rev 3; rev 1 asked, and its "No" was ambiguous).
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
    -- The shot is taken as the step completes, so the flipped layout must still be up then (rev 1
    -- asked to switch back in the same step, and its shot showed the original growth).
    { text = "In /buffy config, switch Window growth to the other direction and close the config. "
          .. "Do the rows grow the other way? (Leave it flipped for the screenshot.)", ask = true,
      screenshot = "growth flipped" },
    { text = "Switch Window growth back in /buffy config, then press Next." },
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

-- ─── #52: what a cooldown pane can read ────────────────────────────────────
-- Addon messages in combat and in instances are not asked: delivery in combat was measured on
-- 70790 (porting guide, PARTY/RAID), and the owner reports addon messaging working in instances
-- since 2026-11-04.

Probe:Steps("cd", {
    rev = 2,                                   -- 2: the inspect reply must be the requested player's
    title = "Cooldown pane: own casts and talents (#52)",
    { text = "Out of combat, ideally on a Priest with Power Infusion or a Druid of 40+. Reading your "
          .. "talents through the traits system.", auto = true,
      run = function()
          local r = ownTraits()
          return r and r.nodes, r and r.ranked, r and #r.spells, r and r.pi
      end,
      check = function()
          local r = lastTraits
          return r ~= nil and r.nodes > 0, "nodes " .. show(r and r.nodes) .. ", ranked " .. show(r and r.ranked)
      end },
    { text = "Press Arm, then cast an instant spell out of combat (a buff is fine).", button = "Arm",
      run = function() armedAt = casts; return casts end },
    { text = "Cast it now, out of combat.", timeout = 180, wait = function() return castSince(false) end,
      check = function()
          return lastCast ~= nil and not lastCast.secretID, "spellID " .. (lastCast and lastCast.secretID and "secret" or "plain")
      end },
    { text = "Enter combat (a training dummy or a mob).", timeout = 600,
      wait = function() if combatState() then return true end; return false, "not in combat yet" end },
    { text = "Press Arm, then cast an instant spell in combat: Power Infusion or Innervate if you have it, "
          .. "otherwise any instant (a buff on yourself is fine).", button = "Arm",
      run = function() armedAt = casts; return casts end },
    { text = "Cast it now, in combat.", timeout = 300, wait = function() return castSince(true) end,
      check = function()
          return lastCast ~= nil and lastCast.combat and not lastCast.secretID,
              "spellID " .. (lastCast and lastCast.secretID and "secret" or "plain") .. " in combat"
      end },
    { text = "Leave combat.", timeout = 600,
      wait = function() if not combatState() then return true end; return false, "still in combat" end },
    { text = "Optional, skip if no one is around: target another player within inspect range, ideally "
          .. "a Priest of 40+ or a Druid, then press Inspect.", button = "Inspect",
      run = requestInspect },
    { text = "Waiting for that player's inspect reply.", timeout = 30,
      wait = function()
          if inspectGot then
              return true, inspectGot.nodes, inspectGot.ranked, #inspectGot.spells, inspectGot.pi
          end
          return false, "no reply for the inspected player yet"
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

NS._test = { Probe = Probe, state = state, stateOK = stateOK, spells = spells, spellsOK = spellsOK,
             casts = function() return casts, lastCast end, walkTraits = walkTraits, ownTraits = ownTraits,
             castSince = castSince, requestInspect = requestInspect,
             inspectState = function() return inspectWant, inspectGot end }
