local H = { run = 0, failures = 0 }
local library = os.getenv("LIBGROUPBUFFS") or "../LibGroupBuffs"
local glass = os.getenv("LIBGLASS") or "../LibGlass"
local function read(path)
    local f = assert(io.open(path, "rb"), path)
    local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
H.read = read
function H.check(ok, msg)
    H.run = H.run + 1
    if not ok then H.failures = H.failures + 1; print("FAIL: " .. (msg or "assertion")) end
end
function H.eq(a, b, msg) H.check(a == b, (msg or "values") .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
function H.near(a, b, msg) H.check(type(a) == "number" and math.abs(a-b)<0.0001, msg) end
local function xml(root, path)
    local dir = path:match("^(.*/)") or ""
    local s = read(root .. "/" .. path):gsub("<!%-%-.-%-%->", "")
    for tag, file in s:gmatch('<(%a+)%s+file="([^"]+)"') do
        local p = dir .. file:gsub("\\", "/")
        if tag == "Include" then xml(root,p)
        elseif tag == "Script" then assert(loadfile(root .. "/" .. p))("Buffy", {}) end
    end
end
function H.load(class, suite, beforeLogin)
    dofile(library .. "/tests/wow_stubs.lua")
    WoW.allowGlobal("Buffy", "BuffyDB", "BuffyAccountDB", "SLASH_BUFFY1", "GlassUI")
    -- Confirmed in Forever 1.60.1.70532's method dump; the shared stub covers the window only.
    WoW.allowMethod("SetNormalTexture", "SetPushedTexture", "SetHighlightTexture", "SetCheckedTexture", "EnableKeyboard")
    WoW.SetPlayerDefaults({ class = class or "PRIEST", name = "Buffy Test", level = 60 })
    WoW.reset()
    Buffy, LibStub, BuffyDB, BuffyAccountDB = nil, nil, nil, nil
    GlassUI = suite and { Suite = suite } or nil
    xml(glass, "LibGlass-1.0.xml")
    xml(library, "LibGroupBuffs-1.0.xml")
    for line in read("Buffy.toc"):gmatch("[^\n]+") do
        if line:match("^[^#].*%.lua$") then assert(loadfile(line))("Buffy", {}) end
    end
    if beforeLogin then beforeLogin() end
    WoW.dispatch("ADDON_LOADED", "Buffy")
    if Buffy.class then
        for _, d in ipairs(Buffy.class.defs) do
            WoW.Know(d.snglID, d.sngl)
            if d.grpID then WoW.DefineSpell(d.grpID, d.grp) end
        end
    end
    WoW.dispatch("PLAYER_LOGIN")
    WoW.flushTimers()
    return Buffy
end
function H.done(name)
    print(name .. ": " .. (H.run-H.failures) .. "/" .. H.run .. " passed")
    if H.failures > 0 then os.exit(1) end
end
return H
