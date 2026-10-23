local H = dofile("tests/harness.lua")
local toc = H.read("Buffy.toc")
H.check(toc:find("## Interface: 16001", 1, true), "Forever interface")
H.check(toc:find("## X-Curse-Project-ID: 1760483", 1, true), "CurseForge identity")
H.check(toc:find("## SavedVariables: BuffyAccountDB", 1, true), "account store")
H.check(toc:find("## SavedVariablesPerCharacter: BuffyDB", 1, true), "character store")
H.check(toc:find("## OptionalDeps: GlassUI", 1, true), "suite load order")
local glassAt = toc:find("Libs\\LibGlass-1.0", 1, true)
local groupAt = toc:find("Libs\\LibGroupBuffs-1.0", 1, true)
H.check(glassAt and groupAt and glassAt < groupAt, "glass loaded before group library")
local P = dofile("tests/pkgmeta.lua")
local external = assert(P.externals())
H.eq(external["Libs/LibGlass-1.0"].ref, "r11", "glass immutable release pin")
local pin = external["Libs/LibGroupBuffs-1.0"]
H.check(pin.kind == "commit" and #pin.ref == 40 and pin.ref:match("^%x+$"), "development library pinned to full commit")
H.check(H.read("BuffyCompat.lua"):find("NEEDS_MINOR = 32", 1, true), "new appearance API floor")
local logo = assert(io.open("Media/Logo.tga", "rb"))
local header = logo:read(18); logo:close()
H.eq(header:byte(3), 2, "uncompressed TGA")
H.eq(header:byte(13) + header:byte(14)*256, 256, "power-of-two width")
H.eq(header:byte(15) + header:byte(16)*256, 256, "power-of-two height")
H.eq(header:byte(17), 32, "32-bit texture")
local pkg = H.read(".pkgmeta")
for _, path in ipairs({ "tests", "Tools", "docs", "Media/Logo.png", "Libs/LibGroupBuffs-1.0/Tools" }) do
    H.check(pkg:find("  - " .. path .. "\n", 1, true), "package excludes " .. path)
end
for line in toc:gmatch("[^\n]+") do
    if line:match("^[^#].*%.lua$") then
        local source = H.read(line)
        H.check(not source:find("@project-version@", 1, true), "no substituted version comparison in " .. line)
        H.check(not source:find("SLASH_PRIESTLY",1,true) and not source:find("SLASH_WILDLY",1,true)
            and not source:find("SLASH_MAGELY",1,true), "no original slash registration in " .. line)
    end
end
H.done("manifest")
