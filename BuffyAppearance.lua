-- Resolve the optional GlassUI contract once, after saved variables load.
local B = Buffy
if not B.API then return end
local started, following, body, accent, material

local function Number(v, max)
    return type(v) == "number" and v == v and v >= 0 and v <= max
end
local function Color(c, n)
    if type(c) ~= "table" then return false end
    for i = 1, n do if not Number(c[i], 1) then return false end end
    return true
end
local function Call(s, name, ...)
    if type(s[name]) ~= "function" then return nil end
    local ok, result = pcall(s[name], ...)
    if ok then return result end
end

function B.StartAppearance()
    if started then return end
    started = true
    local lib, minor = LibStub("LibGlass-1.0", true)
    local gui = rawget(_G, "GlassUI")
    local suite = type(gui) == "table" and gui.Suite
    if type(suite) ~= "table" or suite.API ~= 1 or type(suite.Theme) ~= "function"
        or type(suite.Report) ~= "function" then suite = nil end
    local state = { api = 1, live = false, minor = minor, options = function() B.OpenConfig() end }
    if suite then
        local answer = Call(suite, "Theme", "Buffy")
        if type(answer) == "table" and type(answer.preset) == "string" then
            local look = Call(suite, "Look")
            local tint = type(look) == "table" and look.tint
            local a = type(look) == "table" and look.accent
            local b = type(tint) == "string" and Call(suite, "Body", tint)
            local rgb = type(a) == "string" and Call(suite, "Accent", a)
            if type(b) == "table" and Number(b.wash, 10) and Color(b.backing, 4)
                and (Color(b.tint, 4) or (tint == "class" and Number(b.classShade, 1)))
                and Color(rgb, 3) then
                local ok, made = pcall(lib.New, lib, { preset = answer.preset })
                if ok and type(made) == "table" then
                    material = made
                    local tc = b.tint
                    if not Color(tc, 4) then
                        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[B.classToken]
                        if color then tc = { color.r * b.classShade, color.g * b.classShade,
                            color.b * b.classShade, made.STYLE.tint[4] } end
                    end
                    if Color(tc, 4) then
                        body = { tint = { unpack(tc) }, wash = b.wash, backing = { unpack(b.backing) } }
                        accent = { unpack(rgb) }
                        following = true
                        state.built = answer.preset
                        state.look = { tint = tint, accent = a }
                    else state.reason = "build-failed" end
                else
                    state.reason = (minor or 0) < 11 and "library-too-old" or "build-failed"
                end
            else state.reason = "build-failed" end
        end
    end
    if not following then
        local ok, made = pcall(lib.New, lib, { preset = "clean" })
        if ok then material = made else
            material = nil
            B.Say("Could not build the standalone material: " .. tostring(made))
        end
    end
    if suite then pcall(suite.Report, "Buffy", state) end
    if state.reason then B.Say("GlassUI appearance could not be applied (" .. state.reason .. "); using Clean.") end
end

function B.FollowingSuite() return following == true end
function B.Material() return material end
function B.BodyStyle() return body end
function B.Appearance()
    local look = B.class.appearance()
    if accent then
        local r, g, b = unpack(accent)
        look.title = string.format("|cff%02x%02x%02xBuffy|r", r * 255, g * 255, b * 255)
        look.border, look.popBorder = { r, g, b, 0.85 }, { r, g, b, 1 }
        look.headerLine, look.footerLine = { r, g, b, 0.55 }, { r, g, b, 0.40 }
        look.popDivider, look.groupText = { r, g, b, 0.55 }, { r, g, b, 1 }
        look.header = { body.tint[1], body.tint[2], body.tint[3], 0.98 }
    end
    return look
end
