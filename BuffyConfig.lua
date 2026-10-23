-- All saved writes live here. Profiles are account-wide by class; window state is per character.
local B = Buffy
if not B.API then return end
local API = B.API
local settings, build
local modes = { always = true, detect = true, instance = true }
local thorns = { default = true, tanks = true, self = true, everyone = true, disabled = true }
local unknownInstances = {}

local function Account()
    if type(BuffyAccountDB) ~= "table" then BuffyAccountDB = {} end
    if type(BuffyAccountDB.classes) ~= "table" then BuffyAccountDB.classes = {} end
    return BuffyAccountDB
end

local function Character()
    if type(BuffyDB) ~= "table" then BuffyDB = {} end
    return BuffyDB
end

function B.Profile()
    if not B.class then return nil end
    local classes = Account().classes
    if type(classes[B.classToken]) ~= "table" then classes[B.classToken] = {} end
    return classes[B.classToken]
end

function B.Get(key)
    local db = B.Profile()
    return db and db[key]
end

function B.WindowState(key) return Character()[key] end

function B.SetWindowState(key, value)
    assert(key == "visible" or key == "pos", "unknown window state")
    local db = Character()
    if db[key] == value then return end
    db[key] = value
    if settings then settings:Changed(key) end
end

function B.SetConfig(key, value)
    if not settings then return end
    settings:Set(key, value)
end

function B.SetInstance(id, name, tracked)
    if not settings or not B.class.modeKeys[id] then return end
    settings:SetIn(id .. "Instances", name, tracked == true)
end

function B.InitConfig()
    local db = B.Profile()
    if not db then return end
    settings = B.GB.Settings({
        scopes = {
            { label = "class profile", get = B.Profile },
            { label = "per-character", get = Character },
        },
        -- Inherited measurements, not a claim Buffy has been tested in game.
        measuredOnBuild = "70338",
        onChanged = function(key) if B.OnConfigChanged then B.OnConfigChanged(key) end end,
    })
    for k, v in pairs(B.class.defaults) do
        if db[k] == nil or type(db[k]) ~= type(v) then settings:Set(k, v) end
    end
    for id, key in pairs(B.class.modeKeys) do
        if not modes[db[key]] then settings:Set(key, B.class.defaults[key]) end
        local mapKey = id .. "Instances"
        if type(db[mapKey]) ~= "table" then settings:Set(mapKey, {}) end
        for _, entry in ipairs(B.class.instances) do
            local name = entry.name or entry[1]
            local default = entry.default
            if id == "amplify" then default = entry[3] end
            if id == "dampen" then default = entry[4] end
            if db[mapKey][name] == nil then settings:SetIn(mapKey, name, default == true) end
        end
    end
    if B.classToken == "DRUID" and not thorns[db.thornsMode] then settings:Set("thornsMode", "default") end
    if db.popoverSide ~= "auto" and db.popoverSide ~= "left" and db.popoverSide ~= "right" then
        settings:Set("popoverSide", "auto")
    end
    for _, opt in ipairs({ { "frameAlpha", 0, 1, 0.96 }, { "frameScale", 0.5, 2.5, 1 } }) do
        local n = db[opt[1]]
        if type(n) ~= "number" or n ~= n or n < opt[2] or n > opt[3] then settings:Set(opt[1], opt[4]) end
    end
    if B.WindowState("visible") == nil then B.SetWindowState("visible", true) end
    build = API.ClientBuild() or "?"
end

B.reportFilters.newBuild = function()
    local version = API.AddonVersion("Buffy")
    if version ~= "dev" and version ~= "@" .. "project-version@" then return nil end
    local account, current = Account(), API.ClientBuild()
    if account.seenBuild == current then return nil end
    account.seenBuild = current
    return "Client build " .. tostring(current) .. ": Buffy still needs in-game acceptance on this build."
end

function B.EnteringWorld(initial, reload)
    if settings then settings:HandleEnteringWorld(initial, reload) end
end

function B.LearnDuration(spell, seconds)
    if type(spell) ~= "string" or type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then return end
    local db = B.Profile()
    if not db then return end
    local store = db.learnedDurations
    if type(store) ~= "table" or store.build ~= build then
        store = { build = build }
        db.learnedDurations = store
    end
    if store[spell] == seconds then return end
    store[spell] = seconds
    settings:Changed("learnedDurations")
end

function B.LearnedDuration(spell)
    local store = B.Get("learnedDurations")
    if type(store) == "table" and store.build == build then return store[spell] end
end

function B.IsBuffEnabled(id)
    if not B.class then return false end
    if id == "thorns" then return B.Get("thornsMode") ~= "disabled" end
    local key = B.class.enabledKeys[id]
    return not key or B.Get(key) ~= false
end

function B.IsVisible(def, groups, ord)
    local key = B.class.modeKeys[def.id]
    if not key then return true end
    local mode = B.Get(key)
    if mode == "always" then return true end
    if mode == "detect" then
        for _, group in ipairs(ord or {}) do
            for _, member in ipairs(groups[group] or {}) do
                local state = B.engine:ReadAura(member.unit, def.names)
                if state == "HAS" or state == "BLOCKED" then return true end
            end
        end
        return false
    end
    local name, kind, _, _, _, _, _, mapID = GetInstanceInfo()
    if not name or name == "" or kind == "none" then return false end
    local entry
    -- Priest's map ID aliases survive a localized/renamed instance name.
    for _, candidate in ipairs(B.class.instances) do
        if mapID and mapID ~= 0 and candidate.mapID == mapID then entry = candidate; break end
    end
    if not entry then
        for _, candidate in ipairs(B.class.instances) do
            if (candidate.name or candidate[1]) == name then entry = candidate; break end
        end
    end
    if not entry then
        if (kind == "party" or kind == "raid") and not unknownInstances[name] then
            unknownInstances[name] = true
            B.Say("Unrecognized instance: " .. tostring(name) .. " (" .. tostring(mapID)
                .. "). Please report it for the instance buff list.")
        end
        return false
    end
    local saved = B.Get(def.id .. "Instances")
    return type(saved) == "table" and saved[entry.name or entry[1]] == true
end
