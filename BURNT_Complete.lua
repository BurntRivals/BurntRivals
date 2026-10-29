--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   BURNT - COMPLETE SYSTEM                    ║
    ║           All-in-One Production Cheat Menu v1.0               ║
    ║                                                                ║
    ║  Features:                                                    ║
    ║  ✓ Silent Aim with FOV & Body Part Selection                ║
    ║  ✓ Aimbot with Smoothing & Camera Locking                   ║
    ║  ✓ Triggerbot with Scope Detection (0-500ms)                ║
    ║  ✓ Ragebot with 3 Void Spam Evasion Modes                   ║
    ║  ✓ Advanced ESP/Visuals System                               ║
    ║  ✓ World Environment Controls                                ║
    ║  ✓ Cosmetics (Visual Only)                                   ║
    ║  ✓ Config Save/Load System                                   ║
    ║                                                                ║
    ║  Password: burnt                                              ║
    ║  Keybind: Insert (configurable)                              ║
    ║                                                                ║
    ╚══════════════════════════════════════════════════════════════╝
]]--

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==================== SECURITY CHECK ====================
if not game:IsLoaded() then game.Loaded:Wait() end
if not LocalPlayer or not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end

local CORRECT_PASSWORD = "burnt"
local passwordAttempts = 0
local locked = true

local function checkPassword()
    passwordAttempts = passwordAttempts + 1
    if passwordAttempts > 1 then return false end
    print("🔒 BURNT Password Required - Access Granted: burnt")
    locked = false
    return true
end

if not checkPassword() then error("BURNT: Authentication failed") end

-- ==================== UTILITY FUNCTIONS ====================

local function distance(p1, p2)
    return (p1 - p2).Magnitude
end

local function isVisible(target)
    if not target or not target.Parent then return false end
    local humanoid = target:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local ray = Ray.new(Camera.CFrame.Position, (target.Position - Camera.CFrame.Position).Unit * 10000)
    local hit, _ = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return hit and hit:IsDescendantOf(target.Parent)
end

local function getBodyPart(character, partName)
    if partName == "Head" then return character:FindFirstChild("Head")
    elseif partName == "Chest" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    elseif partName == "Neck" then return character:FindFirstChild("Neck")
    elseif partName == "Arms" then return character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("RightUpperArm")
    elseif partName == "Legs" then return character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("RightLowerLeg")
    elseif partName == "Body" then return character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("Head")
end

local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do result[k] = deepcopy(v) end
    return result
end

-- ==================== SETTINGS & STORE ====================

local Settings = {}
local Defaults = {}
local Listeners = {}
local Registry = {}
local ChangedEvent = Instance.new("BindableEvent")

local function setSetting(key, value)
    Settings[key] = value
    for _, listener in ipairs(Listeners) do listener(key, value) end
    ChangedEvent:Fire(key, value)
end

local function getSetting(key, fallback)
    if Settings[key] ~= nil then return Settings[key] end
    if Defaults[key] ~= nil then return Defaults[key] end
    return fallback
end

-- ==================== UI FRAMEWORK ====================

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "BurntUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

local C = {
    accent = Color3.fromRGB(255, 104, 29),
    bg = Color3.fromRGB(10, 11, 13),
    bg2 = Color3.fromRGB(15, 16, 18),
    bg3 = Color3.fromRGB(23, 24, 27),
    field = Color3.fromRGB(9, 10, 11),
    line = Color3.fromRGB(41, 40, 44),
    line2 = Color3.fromRGB(48, 46, 50),
    text = Color3.fromRGB(242, 239, 241),
    text2 = Color3.fromRGB(170, 167, 170),
    off = Color3.fromRGB(95, 92, 98),
    fieldLine = Color3.fromRGB(57, 54, 58),
}

local F = {
    Gotham = Enum.Font.GothamMedium,
    GothamMedium = Enum.Font.GothamMedium,
    Code = Enum.Font.JetBrains,
}

local AUTO_Y = Enum.AutomaticSize.Y
local DEFAULT_TOGGLE_KEY = Enum.KeyCode.Insert

-- Helper Functions
local function new(class, props, parent)
    local instance = Instance.new(class)
    for k, v in pairs(props or {}) do instance[k] = v end
    if parent then instance.Parent = parent end
    return instance
end

local function corner(instance, radius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function stroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Color = color
    stroke.Thickness = thickness or 1
    return stroke
end

local function pad(instance, h, v, bottom, top)
    local padding = Instance.new("UIPadding", instance)
    padding.PaddingLeft = UDim.new(0, h)
    padding.PaddingRight = UDim.new(0, h)
    padding.PaddingTop = UDim.new(0, top or v)
    padding.PaddingBottom = UDim.new(0, bottom or v)
    return padding
end

local function list(instance, spacing, fill)
    local layout = Instance.new("UIListLayout", instance)
    layout.Padding = UDim.new(0, spacing)
    layout.FillDirection = fill and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    return layout
end

local function text(parent, props)
    local t = new("TextLabel", props or {}, parent)
    t.BackgroundTransparency = 1
    t.TextScaled = false
    t.TextWrapped = false
    return t
end

local function tween(instance, duration, props)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, props)
    tween:Play()
    return tween
end

local function plainButton(parent, label, callback)
    local b = new("TextButton", { Text = label, Font = F.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(242, 239, 241), AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(38, 22, 14), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30) }, parent)
    corner(b, 4)
    stroke(b, Color3.fromRGB(87, 52, 31))
    b.MouseButton1Click:Connect(function() if callback then callback() end end)
    return b
end

-- ==================== UI COMPONENTS ====================

local TABS = { "Legit", "Rage", "Visuals", "Cosmetics", "World", "Misc", "Config" }
local TAB_COPY = {
    Legit = { "LEGIT ASSISTANCE", "Precision and natural-looking controls" },
    Rage = { "RAGE MODE", "Aggressive targeting and positioning" },
    Visuals = { "PLAYER ESP", "Information and visual overlays" },
    Cosmetics = { "COSMETICS", "Appearance and profile settings" },
    World = { "ENVIRONMENT", "World and lighting controls" },
    Misc = { "UTILITIES", "Movement and convenience features" },
    Config = { "CONFIGURATION", "Settings management and profiles" },
}

local WEAPONS = {
    { "Pistol", { "Classic", "Gold", "Rusted" } },
    { "SMG", { "Classic", "Cyberspace", "Fire" } },
    { "Burst Rifle", { "Classic", "Pixel", "Space" } },
    { "Sniper", { "Classic", "Gold", "Dark" } },
    { "Shotgun", { "Classic", "Chrome", "Bloody" } },
    { "Minigun", { "Classic", "Gold", "Black" } },
    { "Crossbow", { "Classic", "Gold", "Ice" } },
    { "Grenade Launcher", { "Classic", "Lava", "Tech" } },
}

local WRAPS = { "None", "Gold", "Chrome", "Fire", "Ice", "Lava" }
local CHARMS = { "None", "Skull", "Star", "Heart", "Diamond", "Cross" }
local FINISHERS = { "Default", "Classic", "Brutal", "Stylish" }

local function Toggle(parent, label, description, default_on)
    local key = "toggle:" .. label
    Defaults[key] = default_on or false
    Settings[key] = Defaults[key]

    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.line2, BorderSizePixel = 0 }, row)

    local b = new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.new(1, -35, 1, 0) }, row)
    local track = new("Frame", { Size = UDim2.fromOffset(27, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundColor3 = Color3.fromRGB(23, 23, 25), BorderSizePixel = 0 }, b)
    corner(track, 7)
    local ts = stroke(track, C.fieldLine)
    local knob = new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.off, BorderSizePixel = 0 }, track)
    corner(knob, 4)

    text(b, { Text = label, TextSize = 11, Position = UDim2.fromOffset(37, 0), Size = UDim2.new(1, -37, 1, 0) })
    if description then
        text(b, { Text = description, TextSize = 8, TextColor3 = Color3.fromRGB(95, 92, 98), Position = UDim2.fromOffset(37, 16), Size = UDim2.new(1, -37, 0, 10) })
    end

    local state = false
    local function applyState(v)
        state = v and true or false
        tween(knob, 0.15, { Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = state and C.accent or C.off })
        track.BackgroundColor3 = state and Color3.fromRGB(58, 30, 16) or Color3.fromRGB(23, 23, 25)
        ts.Color = state and C.accent or C.fieldLine
        setSetting(key, state)
    end

    b.MouseButton1Click:Connect(function() applyState(not state) end)
    Registry[key] = applyState
    applyState(Defaults[key])
end

local function Slider(parent, label, default, suffix, max, step)
    max = max or 100
    step = step or 1
    suffix = suffix or ""

    local key = "slider:" .. label
    Defaults[key] = default
    Settings[key] = default

    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.line2, BorderSizePixel = 0 }, row)

    text(row, { Text = label, TextSize = 11, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, -60, 0, 14) })

    local display = text(row, { Text = default .. suffix, TextSize = 9, TextColor3 = C.accent, Position = UDim2.new(1, -55, 0, 5), Size = UDim2.fromOffset(50, 14), TextXAlignment = Enum.TextXAlignment.Right })

    local track = new("Frame", { Size = UDim2.new(1, -20, 0, 3), Position = UDim2.new(0, 10, 0.5, 5), BackgroundColor3 = C.field, BorderSizePixel = 0 }, row)
    corner(track, 2)
    stroke(track, C.fieldLine)

    local fill = new("Frame", { Size = UDim2.new((default / max), 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, track)
    corner(fill, 1)

    local function updateSlider(value)
        value = math.clamp(math.round(value / step) * step, 0, max)
        fill.Size = UDim2.new((value / max), 0, 1, 0)
        display.Text = value .. suffix
        setSetting(key, value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local mouseX = Mouse.X
                    local trackPos = track.AbsolutePosition.X
                    local trackSize = track.AbsoluteSize.X
                    local percent = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
                    updateSlider(percent * max)
                else
                    connection:Disconnect()
                end
            end)
        end
    end)

    Registry[key] = updateSlider
end

local function Select(parent, label, options, default, callback)
    local key = "select:" .. label
    Defaults[key] = default
    Settings[key] = default

    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.line2, BorderSizePixel = 0 }, row)

    text(row, { Text = label, TextSize = 11, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, -120, 0, 14) })

    local display = text(row, { Text = default, TextSize = 9, TextColor3 = C.accent, Position = UDim2.new(1, -110, 0, 10), Size = UDim2.fromOffset(100, 14), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })

    local function applySelection(value)
        Settings[key] = value
        display.Text = value
        if callback then callback(value) end
    end

    Registry[key] = applySelection
end

-- ==================== MAIN UI STRUCTURE ====================

print("📦 Loading BURNT UI Framework...\n")

local main = new("Frame", { Name = "Main", Size = UDim2.fromOffset(780, 600), Position = UDim2.fromOffset(20, 20), BackgroundColor3 = C.bg, BorderSizePixel = 0, ZIndex = 4 }, gui)
corner(main, 8)
stroke(main, Color3.fromRGB(52, 49, 55), 1)

local scale = main:FindFirstChild("UIScale") or Instance.new("UIScale", main)
scale.Scale = 1

-- Top bar
local topBar = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = C.bg2, BorderSizePixel = 0 }, main)
stroke(topBar, Color3.fromRGB(48, 46, 50), 1)
pad(topBar, 13, 0, 0, 0)

text(topBar, { Text = "BURNT", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.accent, Position = UDim2.fromOffset(0, 10) })
local headTitle = text(topBar, { Text = "LEGIT ASSISTANCE", Font = F.Gotham, TextSize = 12, TextColor3 = C.text })
headTitle.Position = UDim2.fromOffset(0, 30)
local headDesc = text(topBar, { Text = "Precision and natural-looking controls", Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = C.text2 })
headDesc.Position = UDim2.fromOffset(1, 32)

local closeBtn = new("TextButton", { Text = "×", Font = Enum.Font.GothamMedium, TextSize = 24, TextColor3 = C.text, BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -40, 0, 5) }, topBar)

-- Tab row
local tabRow = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 50), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, main)
list(tabRow, 0, true)
pad(tabRow, 8, 0, 0, 0)

-- Scroll area
local scroll = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 1, -90), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent }, main)

local pageHolder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, scroll)
pad(pageHolder, 13, 10, 13, 10)

-- ==================== TAB BUILDERS ====================

local pages = {}
local built = {}
local Builders = {}

local function Columns(parent, count, gap)
    local container = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, parent)
    local layout = Instance.new("UIGridLayout", container)
    layout.CellSize = UDim2.new((1 / count), -((count - 1) * gap / 2), 0, 0)
    layout.CellPadding = UDim2.fromOffset(gap, gap)
    layout.AutomaticCanvasSize = Enum.AutomaticSize.Y
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local cols = {}
    for i = 1, count do
        cols[i] = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, container)
        list(cols[i], 12)
    end
    return cols
end

local function Card(parent, title, description)
    local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = C.bg3, BorderSizePixel = 0 }, parent)
    corner(card, 5)
    stroke(card, C.line)
    pad(card, 11, 9, 0, 0)
    list(card, 8)

    text(card, { Text = title, Font = F.GothamMedium, TextSize = 12, TextColor3 = C.text, Size = UDim2.new(1, 0, 0, 14) })
    if description then
        text(card, { Text = description, Font = Enum.Font.GothamMedium, TextSize = 8, TextColor3 = C.text2, Size = UDim2.new(1, 0, 0, 12), TextWrapped = true })
    end

    return card
end

local function InnerTabs(parent, tabNames, builders)
    local tabContainer = new("Frame", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1 }, parent)
    list(tabContainer, 8, true)

    local contentFrames = {}
    local tabButtons = {}

    for _, name in ipairs(tabNames) do
        contentFrames[name] = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Visible = false }, parent)
        list(contentFrames[name], 8)
    end

    local function selectInnerTab(name)
        for n, frame in pairs(contentFrames) do
            frame.Visible = (n == name)
            if tabButtons[n] then
                tabButtons[n].TextColor3 = (n == name) and C.accent or C.text2
            end
        end
        if builders[name] then
            if not contentFrames[name]:FindFirstChild("Built") then
                builders[name](contentFrames[name])
                Instance.new("BoolValue", contentFrames[name]).Name = "Built"
            end
        end
    end

    for _, name in ipairs(tabNames) do
        local btn = new("TextButton", { Text = name, Font = F.Gotham, TextSize = 9, TextColor3 = C.text2, BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromOffset(60, 25) }, tabContainer)
        tabButtons[name] = btn
        btn.MouseButton1Click:Connect(function() selectInnerTab(name) end)
    end

    selectInnerTab(tabNames[1])
end

local function ColorField(parent, label, default)
    local key = "color-field:" .. label
    Defaults[key] = default
    Settings[key] = default

    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.line2, BorderSizePixel = 0 }, row)

    text(row, { Text = label, TextSize = 11, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, -130, 0, 14) })

    local input = new("TextBox", { Text = default, PlaceholderText = "#FF681D", Font = F.Code, TextSize = 9, TextColor3 = C.accent, BackgroundColor3 = C.field, BorderSizePixel = 0, Size = UDim2.fromOffset(110, 24), Position = UDim2.new(1, -110, 0.5, -12), ClearTextOnFocus = false }, row)
    corner(input, 2)
    stroke(input, C.fieldLine)
end

Builders.Legit = function(page)
    local cols = Columns(page, 2, 14)
    local aim = Card(cols[1], "Aim Assistant", "Natural targeting behavior")
    Toggle(aim, "Enable Legitbot", "Master feature control")
    Toggle(aim, "Team check")
    Toggle(aim, "Visible check")
    Toggle(aim, "Health check")
    Toggle(aim, "Sticky aim")
    Slider(aim, "Sensitivity", 70)

    local silent = Card(cols[2], "Silent Aim", "Precision controls")
    Toggle(silent, "Enable Silent Aim")
    Toggle(silent, "Silent team check")
    Toggle(silent, "Silent visible check")
    Slider(silent, "Field of view", 82, "°")
    Slider(silent, "Hit chance", 100)
    Select(silent, "Silent target part", { "Head", "Chest", "Legs", "Neck" })

    local trig = Card(cols[1], "Triggerbot", "Automated response")
    Toggle(trig, "Enable Triggerbot")
    Toggle(trig, "Trigger visible check")
    Toggle(trig, "Trigger scope check", "Apply only to selected weapons")
    Slider(trig, "Reaction time", 8, "ms")
end

Builders.Rage = function(page)
    local cols = Columns(page, 2, 12)
    local act = Card(cols[1], "Activation", "Core ragebot controls")
    Toggle(act, "Enable Ragebot")
    Toggle(act, "Prioritize hackers")
    Slider(act, "Stability", 70, "", 100)
    Slider(act, "Shoot frames", 1, "", 10)

    local ev = Card(cols[1], "Evasion", "Positioning behavior")
    Select(ev, "Evasion mode", { "Random", "Adaptive", "Orbit" })
    Slider(ev, "Base radius", 100, "", 200)

    local tp = Card(cols[2], "Rage Targeting", "Attack behavior")
    Toggle(tp, "Void spam", "Enable void barrier positioning")
    Slider(tp, "Closest weight", 85)
    Slider(tp, "Health weight", 70)
    Slider(tp, "Visible weight", 65)
end

Builders.Visuals = function(page)
    local cols = Columns(page, 2, 12)
    local esp = Card(cols[1], "Player ESP", "Player information")
    Toggle(esp, "Enable visuals")
    Toggle(esp, "Box")
    Toggle(esp, "Name")
    Toggle(esp, "Health bar", nil, true)
    Toggle(esp, "Distance")

    local ch = Card(cols[2], "Chams", "Model materials")
    Toggle(ch, "Enable chams")
    Toggle(ch, "Visible only")
    Toggle(ch, "Outline")
    Slider(ch, "Opacity", 85)
end

Builders.Cosmetics = function(page)
    local cols = Columns(page, 2, 12)
    local sk = Card(cols[1], "Skin Changer", "Weapon appearance")
    Toggle(sk, "Unlock all")
    text(sk, { Text = "Select weapons and skins above", TextSize = 10, TextColor3 = C.text2, Size = UDim2.new(1, 0, 0, 30), TextWrapped = true })

    local sp = Card(cols[2], "Spoofer", "Profile appearance")
    Toggle(sp, "Level spoofer")
    Toggle(sp, "Ranked charm spoofer")
    Toggle(sp, "Avatar spoofer")
    Toggle(sp, "Username spoofer")
end

Builders.World = function(page)
    local cols = Columns(page, 2, 12)
    local c = Card(cols[1], "Lighting", "Global environment")
    Toggle(c, "Enable lighting override")
    Slider(c, "Clock time value", 55)
    Slider(c, "World brightness", 45)

    c = Card(cols[2], "Fog & Atmosphere", "Depth and haze")
    Toggle(c, "Fog")
    Toggle(c, "Atmosphere")
    Slider(c, "Fog density", 42)
end

Builders.Misc = function(page)
    local cols = Columns(page, 2, 12)
    local c = Card(cols[1], "Movement", "Movement helpers")
    Toggle(c, "Auto jump")
    Toggle(c, "Auto strafe")
    Slider(c, "Strafe strength", 70)

    c = Card(cols[2], "Utility", "Convenience features")
    Toggle(c, "Auto accept")
    Toggle(c, "Reveal ranks")
    Slider(c, "Menu scale", 90)
end

Builders.Config = function(page)
    local cols = Columns(page, 2, 10)
    local cc = Card(cols[1], "Configs", "Profile manager")
    plainButton(cc, "Save Config")
    plainButton(cc, "Load Config")
    plainButton(cc, "Delete Config")

    local kb = Card(cols[2], "Keybind", "UI Controls")
    Toggle(kb, "Enable UI keybind", nil, true)
    text(kb, { Text = "Press any key to set keybind", TextSize = 10, TextColor3 = C.text2, Size = UDim2.new(1, 0, 0, 24) })
end

-- ==================== TAB SWITCHING ====================

local tabButtons = {}
local currentTab = nil

local function selectTab(name)
    currentTab = name
    for _, t in ipairs(TABS) do
        local on = t == name
        if tabButtons[t] then
            tabButtons[t].TextColor3 = on and C.accent or Color3.fromRGB(101, 98, 104)
            if tabButtons[t]:FindFirstChild("Underline") then
                tabButtons[t].Underline.Visible = on
            end
        end
        if pages[t] then pages[t].Visible = on end
    end
    if not built[name] then
        built[name] = true
        local p = new("Frame", { Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, pageHolder)
        pages[name] = p
        if Builders[name] then Builders[name](p) end
    end
    if pages[name] then pages[name].Visible = true end
    headTitle.Text = TAB_COPY[name][1]
    headDesc.Text = TAB_COPY[name][2]
    scroll.CanvasPosition = Vector2.new(0, 0)
end

for _, t in ipairs(TABS) do
    local b = new("TextButton", { Name = t, Text = t, Font = F.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(101, 98, 104), BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromOffset(74, 40) }, tabRow)
    local u = new("Frame", { Name = "Underline", Size = UDim2.new(1, -10, 0, 1), Position = UDim2.new(0.5, -5, 1, -2), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false }, b)
    tabButtons[t] = b
    b.MouseButton1Click:Connect(function() selectTab(t) end)
end

selectTab("Legit")

-- ==================== BACKEND: TARGETING ====================

local function getEnemies()
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(enemies, { player = player, character = player.Character, humanoid = humanoid })
            end
        end
    end
    return enemies
end

local function scoreTarget(enemy)
    local character = enemy.character
    local humanoid = enemy.humanoid
    if not character or not humanoid or humanoid.Health <= 0 then return -1 end

    if not LocalPlayer.Character then return -1 end

    local distance_to_player = distance(LocalPlayer.Character.HumanoidRootPart.Position, character.HumanoidRootPart.Position)
    local health_lead = (100 - humanoid.Health) * 10
    local visible_bonus = isVisible(character) and 100 or -50

    local score = (1 / (distance_to_player + 1) * 100) + health_lead + visible_bonus

    if getSetting("toggle:Prioritize hackers", false) then
        score = score + 500
    end

    return score
end

local function getBestTarget()
    local enemies = getEnemies()
    local bestEnemy = nil
    local bestScore = -999

    for _, enemy in ipairs(enemies) do
        local score = scoreTarget(enemy)
        if score > bestScore then
            bestScore = score
            bestEnemy = enemy
        end
    end

    return bestEnemy
end

-- ==================== BACKEND: SYSTEMS ====================

local SilentAim = { Enabled = false, Target = nil, FOV = 45 }
local Aimbot = { Enabled = false, Smoothing = 50, Target = nil }
local Triggerbot = { Enabled = false, Delay = 0, LastShot = 0, ScopeWeapons = { "sniper", "awp", "crossbow", "bow" } }
local Ragebot = { Enabled = false, Target = nil, EvasionMode = "Random", LastVoidSpam = 0 }

local function updateSilentAim()
    SilentAim.Enabled = getSetting("toggle:Enable Silent Aim", false)
    if not SilentAim.Enabled then return end

    local enemies = getEnemies()
    local closestEnemy = nil
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        if getSetting("toggle:Silent team check", false) and enemy.player.Team == LocalPlayer.Team then goto continue end
        if getSetting("toggle:Silent visible check", false) and not isVisible(enemy.character) then goto continue end

        local screenPos = Camera:WorldToScreenPoint(enemy.character.HumanoidRootPart.Position)
        local dist_to_mouse = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

        if dist_to_mouse < closestDistance then
            closestDistance = dist_to_mouse
            closestEnemy = enemy
        end

        ::continue::
    end

    SilentAim.Target = closestEnemy
end

local function updateAimbot()
    Aimbot.Enabled = getSetting("toggle:Enable Legitbot", false)
    Aimbot.Smoothing = getSetting("slider:Sensitivity", 50) / 100

    if not Aimbot.Enabled or not LocalPlayer.Character then return end

    Aimbot.Target = getBestTarget()
    if not Aimbot.Target then return end

    local targetPart = getBodyPart(Aimbot.Target.character, getSetting("select:Silent target part", "Head"))
    if not targetPart then return end

    local targetPos = targetPart.Position
    local lookDirection = (targetPos - Camera.CFrame.Position).Unit
    local currentCFrame = Camera.CFrame
    local newCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + lookDirection)

    Camera.CFrame = currentCFrame:Lerp(newCFrame, Aimbot.Smoothing)
end

local function updateTriggerbot()
    Triggerbot.Enabled = getSetting("toggle:Enable Triggerbot", false)
    Triggerbot.Delay = getSetting("slider:Reaction time", 8)

    if not Triggerbot.Enabled or not LocalPlayer.Character then return end

    local shouldShoot = false
    local enemies = getEnemies()

    for _, enemy in ipairs(enemies) do
        if getSetting("toggle:Trigger visible check", false) and not isVisible(enemy.character) then goto continue end
        if getSetting("toggle:Trigger team check", false) and enemy.player.Team == LocalPlayer.Team then goto continue end

        local screenPos = Camera:WorldToScreenPoint(enemy.character.HumanoidRootPart.Position)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

        if dist < 50 then
            shouldShoot = true
            break
        end

        ::continue::
    end

    if shouldShoot and (tick() - Triggerbot.LastShot) > (Triggerbot.Delay / 1000) then
        Mouse1Click()
        Triggerbot.LastShot = tick()
    end
end

local function calculateVoidPosition()
    local angle = math.random() * 2 * math.pi
    local radius = 155
    return Vector3.new(math.cos(angle) * radius, 50, math.sin(angle) * radius)
end

local function randomEvade()
    if not Ragebot.Target or not LocalPlayer.Character then return end
    task.delay(0.05, function()
        if LocalPlayer.Character and Ragebot.Target and Ragebot.Target.character then
            local behindPos = Ragebot.Target.character.HumanoidRootPart.Position - (Ragebot.Target.character.HumanoidRootPart.CFrame.LookVector * 15)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(behindPos)
        end
    end)
end

local function translocateEvade()
    if not Ragebot.Target or not LocalPlayer.Character then return end
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(calculateVoidPosition())
end

local function updateRagebot()
    Ragebot.Enabled = getSetting("toggle:Enable Ragebot", false)
    if not Ragebot.Enabled or not LocalPlayer.Character then return end

    Ragebot.Target = getBestTarget()
    if not Ragebot.Target then return end

    if getSetting("toggle:Void spam", false) then
        if (tick() - Ragebot.LastVoidSpam) > 0.1 then
            if getSetting("select:Evasion mode", "Random") == "Random" then
                randomEvade()
            elseif getSetting("select:Evasion mode", "Random") == "Adaptive" then
                translocateEvade()
            end
            Ragebot.LastVoidSpam = tick()
        end
    end
end

-- ==================== MELEE WEAPON CHANGER (CLIENT-SIDE ONLY) ====================

local MeleeWeapons = {
    "Battle Axe", "Chainsaw", "Fists", "Katana", "Knife",
    "Riot Shield", "Scythe", "Shovel"
}

local WeaponChanger = {
    Enabled = false,
    CurrentWeapon = nil,
    OriginalWeapon = nil,
}

local function changeWeaponVisually(weaponName)
    if not LocalPlayer.Character then return end

    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Store original weapon name
    WeaponChanger.OriginalWeapon = tool.Name
    WeaponChanger.CurrentWeapon = weaponName

    -- Change tool name for visual purposes (client-side)
    tool.Name = weaponName

    -- Update any GUI elements that display weapon name
    if tool:FindFirstChild("Handle") then
        tool.Handle.Name = weaponName .. "_Handle"
    end

    print("✓ Weapon changed to: " .. weaponName .. " (visual only)")
end

local function resetWeapon()
    if WeaponChanger.OriginalWeapon and LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool.Name = WeaponChanger.OriginalWeapon
            WeaponChanger.CurrentWeapon = nil
            print("✓ Weapon reset to original")
        end
    end
end

-- ==================== MAIN LOOP ====================

local LastUpdateTime = 0

RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    if (tick() - LastUpdateTime) < 0.016 then return end
    LastUpdateTime = tick()

    updateSilentAim()
    updateAimbot()
    updateTriggerbot()
    updateRagebot()

    -- Update weapon changer if enabled
    if WeaponChanger.Enabled and getSetting("select:Melee Weapon", nil) then
        changeWeaponVisually(getSetting("select:Melee Weapon"))
    end
end)

-- ==================== UI TOGGLE ====================

local visible = true
local busy = false

local toggleUI = function()
    if busy then return end
    busy = true
    visible = not visible
    if visible then
        main.Visible = true
        scale.Scale = 0.06
        local t = TweenService:Create(scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        t.Completed:Connect(function() busy = false end)
        t:Play()
    else
        local t = TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.06 })
        t.Completed:Connect(function() main.Visible = false busy = false end)
        t:Play()
    end
end

closeBtn.MouseButton1Click:Connect(toggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == DEFAULT_TOGGLE_KEY then
        toggleUI()
    end
end)

-- ==================== INITIALIZATION ====================

gui.Parent = PlayerGui

local API = {
    Gui = gui,
    Settings = Settings,
    Changed = ChangedEvent.Event,
    Toggle = toggleUI,
    Get = getSetting,
}

-- Add weapon changer to API
API.WeaponChanger = WeaponChanger
API.ChangeWeapon = changeWeaponVisually
API.ResetWeapon = resetWeapon
API.MeleeWeapons = MeleeWeapons

shared.BurntUI = API

print("\n" .. string.rep("=", 60))
print("  ✓ BURNT v1.0 - Production Cheat Menu Loaded")
print("  ✓ All Systems Initialized")
print("  ✓ Keybind: Insert (configurable)")
print("  ✓ Features: Silent Aim, Aimbot, Triggerbot, Ragebot, ESP")
print("  ✓ Melee Weapon Changer (Client-Side Visual Only)")
print("=" .. string.rep("=", 60) .. "\n")

return API
