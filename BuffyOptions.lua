-- One settings page for the active class, built lazily by the Retail Settings framework.
local B = Buffy
if not B.API then return end
local panel
local function MakeDesc(parent, y, text, indent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", indent or 0, y.v)
    fs:SetWidth(460)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    local height = fs:GetStringHeight()
    y.v = y.v - math.max(28, type(height) == "number" and height or 28) - 6
    return fs
end
local function Check(parent, y, label, get, set)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y.v)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() == true) end)
    cb:SetScript("OnShow", function(self) self:SetChecked(get()) end)
    cb:SetChecked(get())
    y.v = y.v - 28
    return cb
end
local function Choices(parent, y, label, key, choices)
    MakeDesc(parent, y, label)
    local controls = {}
    for _, choice in ipairs(choices) do
        local value = choice[1]
        local cb = Check(parent, y, choice[2], function() return B.Get(key) == value end, function()
            B.SetConfig(key, value)
            for k, control in pairs(controls) do control:SetChecked(k == value) end
        end)
        controls[value] = cb
    end
end

local function MakeSlider(parent, y, opt)
    local SLIDER_W = 220

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y.v)
    label:SetText(opt.label)
    y.v = y.v - 18

    local trackBg = parent:CreateTexture(nil, "BACKGROUND")
    trackBg:SetColorTexture(0.10, 0.10, 0.18, 0.95)
    trackBg:SetSize(SLIDER_W, 10)
    trackBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y.v - 6)

    for _, info in ipairs({
        { "TOPLEFT", "TOPRIGHT" },
        { "BOTTOMLEFT", "BOTTOMRIGHT" },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.35, 0.35, 0.55, 0.80)
        t:SetHeight(1)
        t:SetPoint(info[1], trackBg, info[1])
        t:SetPoint(info[2], trackBg, info[2])
    end
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.35, 0.35, 0.55, 0.80)
        t:SetWidth(1)
        t:SetPoint("TOP" .. side, trackBg, "TOP" .. side)
        t:SetPoint("BOTTOM" .. side, trackBg, "BOTTOM" .. side)
    end

    local trackFill = parent:CreateTexture(nil, "ARTWORK")
    trackFill:SetColorTexture(0.40, 0.40, 0.72, 0.75)
    trackFill:SetPoint("TOPLEFT", trackBg, "TOPLEFT", 1, -1)
    trackFill:SetHeight(8)

    local slider = CreateFrame("Slider", opt.name, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y.v)
    slider:SetSize(SLIDER_W + 8, 18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:SetSize(16, 18) end
    slider:SetMinMaxValues(opt.min, opt.max)
    slider:SetValueStep(opt.step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    local function saved()
        local v = B.Get(opt.key)
        return type(v) == "number" and v or opt.default
    end
    slider:SetValue(saved())

    local lowTxt = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lowTxt:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 2)
    lowTxt:SetText(opt.lowText)
    local highTxt = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    highTxt:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 2)
    highTxt:SetText(opt.highText)

    local valTxt = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valTxt:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valTxt:SetText(opt.format(saved()))

    local function UpdateFill()
        local lo, hi = slider:GetMinMaxValues()
        local pct = (slider:GetValue() - lo) / (hi - lo)
        trackFill:SetWidth(math.max(1, pct * (SLIDER_W - 2)))
    end

    local snap = 1 / opt.step
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * snap + 0.5) / snap
        B.SetConfig(opt.key, value)
        valTxt:SetText(opt.format(value))
        UpdateFill()
        if opt.onChange then opt.onChange(value) end
    end)

    slider:HookScript("OnShow", function() C_Timer.After(0.02, UpdateFill) end)
    C_Timer.After(0.1, UpdateFill)

    y.v = y.v - 40
    if opt.desc then MakeDesc(parent, y, opt.desc, 4) end
    return slider
end

local function BuildPanel()
    if panel.built then return end
    panel.built = true
    panel.controls = {}
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\Buffy\\Media\\Logo")
    logo:SetSize(40, 40)
    logo:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
    title:SetText("Buffy - " .. B.classToken)
    local scroll = CreateFrame("ScrollFrame", "BuffyOptionsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -62)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(490)
    scroll:SetScrollChild(content)
    local y = { v = 0 }
    MakeDesc(content, y, "Buff settings are shared by characters of this class. Window position and visibility belong to this character.")
    for _, opt in ipairs({ { "showSolo", "Show while solo" }, { "trackPets", "Track eligible pets" },
        { "lockFrame", "Lock frame position" }, { "showClickHints", "Show click hints" } }) do
        local key = opt[1]
        panel.controls[key] = Check(content, y, opt[2], function() return B.Get(key) end,
            function(v) B.SetConfig(key, v) end)
    end
    Choices(content, y, "Popover side", "popoverSide", { { "auto", "Automatic" }, { "left", "Left" }, { "right", "Right" } })
    local pct = function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end
    local opacity = MakeSlider(content, y, { label = "Window opacity", key = "frameAlpha", min = 0, max = 1,
        step = 0.01, default = 0.96, lowText = "0%", highText = "100%", format = pct })
    panel.controls.frameAlpha = opacity
    if B.FollowingSuite() then
        opacity:EnableMouse(false)
        opacity:EnableKeyboard(false)
        opacity:SetAlpha(0.45)
        opacity:SetScript("OnValueChanged", function() end)
        MakeDesc(content, y, "Appearance follows GlassUI. Change its Buffy follow switch or its tint/accent, then /reload. Your local opacity is saved for when following is off.")
    end
    panel.controls.frameScale = MakeSlider(content, y, { label = "Window scale", key = "frameScale",
        min = 0.5, max = 2.5, step = 0.05, default = 1, lowText = "50%", highText = "250%", format = pct })
    for _, def in ipairs(B.class.defs) do
        local key = B.class.enabledKeys[def.id]
        if key then
            panel.controls[key] = Check(content, y, "Track " .. def.sngl,
                function() return B.Get(key) end, function(v) B.SetConfig(key, v) end)
        end
        local modeKey = B.class.modeKeys[def.id]
        if modeKey then
            Choices(content, y, def.sngl .. " appears", modeKey, {
                { "always", "Always" }, { "detect", "When detected on a group member" }, { "instance", "In selected instances" },
            })
        end
    end
    if B.class.thornsModes then
        Choices(content, y, "Thorns targets", "thornsMode", {
            { "default", "Automatic: tanks when assigned, otherwise yourself" },
            { "tanks", "Tanks only" }, { "self", "Yourself" },
            { "everyone", "Everyone (excluding pets)" }, { "disabled", "Disabled" },
        })
    end
    for _, def in ipairs(B.class.defs) do
        if B.class.modeKeys[def.id] then
            local id = def.id
            MakeDesc(content, y, def.sngl .. " - selected instances")
            for _, entry in ipairs(B.class.instances) do
                local name = entry.name or entry[1]
                local cb = Check(content, y, name, function() return B.Get(id .. "Instances")[name] end,
                    function(v) B.SetInstance(id, name, v) end)
                local tip = entry.tooltip or entry[5]
                if tip then
                    cb:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(name)
                        GameTooltip:AddLine(tip, 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            end
        end
    end
    content:SetHeight(-y.v + 20)
end

function B.RegisterOptions()
    if panel then return end
    panel = CreateFrame("Frame", "BuffyOptionsPanel")
    panel.name = "Buffy"
    panel:SetScript("OnShow", BuildPanel)
    B.optionsPanel = panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        panel.category = Settings.RegisterCanvasLayoutCategory(panel, "Buffy")
        Settings.RegisterAddOnCategory(panel.category)
    end
end
function B.OpenConfig()
    if panel and panel.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(panel.category:GetID())
    else B.Say("Options are in Game Menu > Options > AddOns > Buffy.") end
end
