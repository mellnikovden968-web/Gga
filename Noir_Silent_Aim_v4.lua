--[[=====================================================================
    NOIR SILENT AIM — IMPROVED  (v4)
    Game : Murder Mystery 2  (placeId 142823291)
    Base : "Noir_Silent_Aim_Identical_UI.lua"
    Notes: rewritten feature modules (gun, knife, ESP, roles, round timer,
           fling, misc) + new controls (keybinds, FOV, auto-fire, tracers,
           skeleton, anti-afk, server hop, chat spam).
    The Velvet UI look is preserved ("identical UI").

    v4.1 — PERFORMANCE PASS (lag/freeze fixes):
      * Object ESP no longer re-scans the whole Workspace on every
        DescendantAdded/Removing; it now adds/removes highlights
        incrementally (O(1)) and only does a full scan on a toggle change.
      * ESP tracer/skeleton loop: cached player list, precomputed bone
        tables, per-player line cache, no per-frame string concatenation,
        Drawing lines freed on respawn / player leave.
      * ESP text/health loop throttled to ~12 Hz and uses cached billboard
        references (also fixed a name collision on the health bar).
      * Motion sampling runs at ~30 Hz and only while an aim feature is on.
      * findDroppedGun uses a registry (no per-tick Workspace scan).
      * Cached: player list, local root/humanoid, friend status, GetPlayerData
        remote, pickup remote, RaycastParams.
      * applyCharacterMods only runs when WalkSpeed/JumpPower is enabled.
      * Gradient stroke animation throttled to ~30 Hz.
      * New "Performance Mode" toggle (MAIN > SELF MODS) for low-end devices.
=======================================================================]]

--============================================================ SERVICES
local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

local guiParent = CoreGui
if type(gethui) == "function" then local ok,v=pcall(gethui); if ok and typeof(v)=="Instance" then guiParent=v end end
pcall(function() local old=guiParent:FindFirstChild("NoirSilentAimUI"); if old then old:Destroy() end end)

--========================================================= PERSISTENCE
local NoirPersistence = {
    data = { toggles = {}, sliders = {}, dropdowns = {}, textboxes = {}, keybinds = {}, positions = {} },
    token = 0,
    path = "NOIR.CONFIG/autosave.json",
    safeLegacy = {
        Enabled=true, ["Wall Check"]=true, ["Show Shoot Murder Button"]=true,
        ["Lock Shoot Murder Button"]=true, ["Knife Silent Aim"]=true, ["Knife Wall Check"]=true,
        ["Prioritize Sheriff"]=true, ["Enable WalkSpeed"]=true, ["Enable JumpPower"]=true,
        ["Show Round Timer"]=true, ["Instant Role Detection"]=true, ["Auto Notify Roles"]=true,
        ["Auto Grab Gun"]=true, ["Auto Grab Gun Safety Check"]=true, ["Gun Aura"]=true,
        ["Auto Notify on Dropped Gun"]=true, ["Gun Pickup Notify"]=true, ["Touch Fling"]=true,
        ["Auto Fling Sheriff / Hero"]=true, ["Auto Fling Murderer"]=true, ["Fling All"]=true,
        ["Anti Fling"]=true, ["Auto Fire"]=true, ["Show FOV"]=true, ["Ignore Dead"]=true,
        ["Ignore Friends"]=true, ["ESP Name"]=true, ["ESP Distance"]=true, ["ESP Health"]=true,
        ["ESP Role"]=true, ["ESP Tracer"]=true, ["ESP Skeleton"]=true, ["Anti AFK"]=true,
    },
}
do
    if type(readfile) == "function" then
        pcall(function()
            local loaded = HttpService:JSONDecode(readfile(NoirPersistence.path))
            if typeof(loaded) == "table" then NoirPersistence.data = loaded end
        end)
    end
    for _, key in ipairs({"toggles","sliders","dropdowns","textboxes","keybinds","positions"}) do
        if typeof(NoirPersistence.data[key]) ~= "table" then NoirPersistence.data[key] = {} end
    end
end
function NoirPersistence.Save()
    if type(writefile) ~= "function" then return end
    NoirPersistence.token += 1
    local token = NoirPersistence.token
    task.delay(.35, function()
        if token ~= NoirPersistence.token then return end
        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("NOIR.CONFIG") then makefolder("NOIR.CONFIG") end
            writefile(NoirPersistence.path, HttpService:JSONEncode(NoirPersistence.data))
        end)
    end)
end
function NoirPersistence.GetPosition(key, fallback)
    local p = NoirPersistence.data.positions[key]
    if typeof(p) == "table" and #p == 4 then return UDim2.new(p[1], p[2], p[3], p[4]) end
    return fallback
end
function NoirPersistence.SetPosition(key, p)
    NoirPersistence.data.positions[key] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    NoirPersistence.Save()
end

--=========================================================== UI THEME
-- Palette sampled straight from the "NOIR ROBLOX HUB" reference image:
-- near-black backdrop, soft graphite panels and a single green accent.
local C = {
    base = Color3.fromRGB(7,8,10), surface = Color3.fromRGB(15,17,20), panel = Color3.fromRGB(13,15,18),
    card = Color3.fromRGB(17,19,23), border = Color3.fromRGB(120,126,134), accent = Color3.fromRGB(93,168,94),
    accent2 = Color3.fromRGB(122,201,122), text = Color3.fromRGB(233,235,238), dim = Color3.fromRGB(124,130,138),
    off = Color3.fromRGB(42,45,50), btn = Color3.fromRGB(35,38,41),
}
function New(class, props)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then x[k] = v end end
    x.Parent = props and props.Parent
    return x
end
function corner(x, r) New("UICorner", { CornerRadius = UDim.new(0, r or 12), Parent = x }) end
local gradientStrokes = {}
local perfMode = false   -- user toggle: skips gradient animation + throttles ESP lines
-- Gradient stroke: a 1px border whose colour sweeps transparent -> lit -> transparent, exactly
-- like the reference cards. Each gradient is stored so the highlight can slowly travel the edge.
function stroke(x, col, tr)
    local s = New("UIStroke", { Color = col or C.border, Transparency = tr or .55, Thickness = 1, Parent = x })
    local g = New("UIGradient", { Parent = s, Rotation = 35, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70,74,80)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(96,101,108)),
        ColorSequenceKeypoint.new(.78, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70,74,80)),
    }) })
    table.insert(gradientStrokes, g)
    return s
end
local gradientAccum = 0
RunService.RenderStepped:Connect(function(dt)
    if #gradientStrokes == 0 then return end
    gradientAccum += dt
    if gradientAccum < 0.04 then return end
    local step = gradientAccum * 30
    gradientAccum = 0
    for i = #gradientStrokes, 1, -1 do
        local g = gradientStrokes[i]
        if g.Parent then
            if not perfMode then g.Rotation = (g.Rotation + step) % 360 end
        else
            table.remove(gradientStrokes, i)
        end
    end
end)
function text(parent, value, size, pos, dim)
    return New("TextLabel", { Parent = parent, BackgroundTransparency = 1, Text = value, TextColor3 = dim and C.dim or C.text,
        TextSize = size, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = UDim2.new(1, 0, 0, size + 8) })
end

--=========================================================== MAIN GUI
local gui = New("ScreenGui", { Name = "NoirSilentAimUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
local scale = New("UIScale", { Parent = gui, Scale = 1 })
function rescale()
    local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.min(v.X / 1450, v.Y / 850, 0.68)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

local win = New("Frame", { Parent = gui, Name = "Window", AnchorPoint = Vector2.new(.5, .5),
    Position = NoirPersistence.GetPosition("window", UDim2.fromScale(.5, .5)), Size = UDim2.fromOffset(1180, 700),
    BackgroundColor3 = C.base, BackgroundTransparency = .04, ClipsDescendants = true, Visible = false })
local winScale = New("UIScale", { Parent = win, Scale = .68 })
corner(win, 22)
local winStroke = stroke(win, C.border, .5); winStroke.Thickness = 1.5
-- subtle sheen: brighter top-left fading to black bottom-right, like the reference backdrop
New("UIGradient", { Parent = win, Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,22,26)),
    ColorSequenceKeypoint.new(.45, Color3.fromRGB(9,10,13)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3,4,6)) }), Rotation = 25 })

--=========================================================== SIDEBAR
local navButtons, navIcons = {}, {}
local sidebar = New("Frame", { Parent = win, Size = UDim2.fromOffset(240, 700), BackgroundColor3 = C.surface, BackgroundTransparency = .28 })
corner(sidebar, 22); stroke(sidebar, C.border, .68)
local logo = New("TextLabel", { Parent = sidebar, Position = UDim2.fromOffset(26, 32), Size = UDim2.fromOffset(190, 42),
    BackgroundTransparency = 1, Text = "NOIR", TextColor3 = C.text, TextSize = 34, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left })
New("UIGradient", { Parent = logo, Color = ColorSequence.new(C.text, C.accent2), Rotation = 0 })
text(sidebar, "R O B L O X   H U B", 10, UDim2.fromOffset(28, 76), true)
do
    local navDefs = {
        { "home",   16898613509, Vector2.new(820, 147), "Home" },
        { "main",   16898613509, Vector2.new(820, 147), "Main" },
        { "aim",    16898613777, Vector2.new(967, 759), "Combat" },
        { "world",  16898613509, Vector2.new(771, 563), "World" },
        { "visual", 16898613353, Vector2.new(771, 563), "Visuals" },
    }
    for i, d in ipairs(navDefs) do
        local b = New("TextButton", { Parent = sidebar, Position = UDim2.fromOffset(16, 116 + (i - 1) * 52), Size = UDim2.fromOffset(208, 46),
            BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Name = d[4] })
        corner(b, 12)
        local ic = New("ImageLabel", { Parent = b, Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1, Image = "rbxassetid://" .. d[2], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = d[3],
            ImageColor3 = C.dim })
        local lbl = New("TextLabel", { Parent = b, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1, Text = d[4], TextColor3 = C.dim, TextSize = 15, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
        local bar = New("Frame", { Parent = b, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = C.accent, BackgroundTransparency = 1 })
        corner(bar, 2)
        navButtons[d[1]] = b; navIcons[d[1]] = { icon = ic, label = lbl, bar = bar }
    end
end
local status = New("Frame", { Parent = sidebar, Position = UDim2.fromOffset(16, 596), Size = UDim2.fromOffset(208, 84), BackgroundColor3 = C.panel, BackgroundTransparency = .18 })
corner(status, 16); stroke(status, C.border, .6)
local statusDot = New("Frame", { Parent = status, Position = UDim2.fromOffset(16, 21), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent })
corner(statusDot, 4)
text(status, "Connected", 13, UDim2.fromOffset(30, 15))
text(status, "Noir Client \u{2022} v4", 15, UDim2.fromOffset(16, 45))

local header = New("Frame", { Parent = win, Position = UDim2.fromOffset(240, 0), Size = UDim2.new(1, -240, 0, 96), BackgroundTransparency = 1 })
text(header, "NOIR HUB", 24, UDim2.fromOffset(28, 24))
text(header, "Silent Aim \u{2022} ESP \u{2022} Prediction", 13, UDim2.fromOffset(29, 56), true)
local creatorImage = ""
do
    local customAsset = (type(getcustomasset) == "function" and getcustomasset) or (type(getsynasset) == "function" and getsynasset)
    if type(writefile) == "function" and customAsset then
        local encoded = "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"
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decoded = encoded:gsub("[^" .. alphabet .. "=]", ""):gsub(".", function(x)
            if x == "=" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        pcall(writefile, "NOIR_CREATOR.jpg", decoded)
        local ok, asset = pcall(customAsset, "NOIR_CREATOR.jpg")
        if ok then creatorImage = asset end
    end
end
local search = New("TextBox", { Parent = header, Position = UDim2.new(1, -470, 0, 26), Size = UDim2.fromOffset(300, 44),
    BackgroundColor3 = C.panel, PlaceholderText = "   Search features...", Text = "", TextColor3 = C.text,
    PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
corner(search, 12); stroke(search)
local icon = New("ImageLabel", { Parent = header, Position = UDim2.new(1, -152, 0, 26), Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = C.panel, Image = creatorImage, ScaleType = Enum.ScaleType.Crop })
corner(icon, 13); stroke(icon, C.border, .45)
if creatorImage == "" then local fb = text(icon, "N", 22, UDim2.fromOffset(0, 8)); fb.TextXAlignment = Enum.TextXAlignment.Center end
-- Small utility buttons use the same visual language as Shoot Murder:
-- dark glass, white animated gradient border, inner border and click sound.
function styleCircularButton(b, diameter)
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    b.BackgroundTransparency = .28
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ClipsDescendants = false
    b.ZIndex = 20
    corner(b, math.floor(diameter / 2))
    local outer = New("UIStroke", { Parent = b, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local gradient = New("UIGradient", { Parent = outer, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    }) })
    table.insert(gradientStrokes, gradient)
    local inner = New("UIStroke", { Parent = b, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner
    table.insert(gradientStrokes, innerGradient)
    local sound = Instance.new("Sound")
    sound.Name = "NoirButtonSound"; sound.SoundId = "rbxassetid://3868133279"; sound.Volume = .35; sound.Parent = b
    local baseTextSize = b.TextSize
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(.18), { BackgroundTransparency = .12, TextSize = baseTextSize + 1 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(.22), { BackgroundTransparency = .28, TextSize = baseTextSize }):Play()
    end)
    b.MouseButton1Down:Connect(function()
        sound:Play()
        TweenService:Create(b, TweenInfo.new(.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(27, 27, 31), Size = UDim2.fromOffset(diameter + 6, diameter + 6) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(8, 8, 10), Size = UDim2.fromOffset(diameter, diameter) }):Play()
    end)
    return b
end
function topButton(txt, x, color)
    local b = New("TextButton", { Parent = header, Position = UDim2.new(1, x, 0, 26), Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = color or C.btn, Text = txt, TextColor3 = C.text, TextSize = 22, Font = Enum.Font.GothamBold })
    return styleCircularButton(b, 44)
end
local mini = topButton("\u{2212}", -98, C.btn)
local close = topButton("\u{00d7}", -48, C.btn)
close.MouseButton1Click:Connect(function()
    TweenService:Create(winScale, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .78 }):Play()
    TweenService:Create(win, TweenInfo.new(.28), { BackgroundTransparency = 1 }):Play()
    task.delay(.29, function() if gui.Parent then gui:Destroy() end end)
end)

-- window drag
local dragging, dragStart, startPos
header.Active = true
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = win.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local half = win.AbsoluteSize / 2
        local desired = Vector2.new(startPos.X.Scale * view.X + startPos.X.Offset * scale.Scale + delta.X,
            startPos.Y.Scale * view.Y + startPos.Y.Offset * scale.Scale + delta.Y)
        desired = Vector2.new(math.clamp(desired.X, half.X, view.X - half.X), math.clamp(desired.Y, half.Y, view.Y - half.Y))
        win.Position = UDim2.fromOffset(desired.X / scale.Scale, desired.Y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then NoirPersistence.SetPosition("window", win.Position) end
        dragging = false
    end
end)

local restore = New("TextButton", { Parent = gui, AnchorPoint = Vector2.new(1, .5), Position = NoirPersistence.GetPosition("restore", UDim2.new(1, -22, .5, 0)),
    Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel, Text = "N", TextColor3 = C.text, TextSize = 30,
    Font = Enum.Font.GothamBold, Visible = false, AutoButtonColor = false })
styleCircularButton(restore, 62)
local restoreDragging, restoreMoved, restoreStart, restorePos = false, false, nil, nil
restore.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        restoreDragging = true; restoreMoved = false; restoreStart = input.Position; restorePos = restore.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - restoreStart
        if delta.Magnitude > 7 then restoreMoved = true end
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local x = math.clamp(restorePos.X.Offset * scale.Scale + delta.X, 34, view.X - 34)
        local y = math.clamp(restorePos.Y.Scale * view.Y + restorePos.Y.Offset * scale.Scale + delta.Y, 34, view.Y - 34)
        restore.Position = UDim2.fromOffset(x / scale.Scale, y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        restoreDragging = false; NoirPersistence.SetPosition("restore", restore.Position)
    end
end)
mini.MouseButton1Click:Connect(function()
    TweenService:Create(winScale, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .72 }):Play()
    task.delay(.28, function() if win.Parent then win.Visible = false; restore.Visible = true end end)
end)
restore.MouseButton1Click:Connect(function()
    if restoreMoved then restoreMoved = false return end
    restore.Visible = false; win.Visible = true; winScale.Scale = .72
    TweenService:Create(winScale, TweenInfo.new(.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

--====================================================== CONTENT PAGES
local content = New("ScrollingFrame", { Parent = win, Position = UDim2.fromOffset(275, 110), Size = UDim2.new(1, -300, 1, -130),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 7, ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollingEnabled = true, Active = true, ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
local cols = {}
for i = 1, 2 do
    cols[i] = New("Frame", { Parent = content, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = cols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local configContent = content:Clone(); configContent.Name = "ConfigContent"; configContent.Parent = win; configContent.Visible = false; configContent:ClearAllChildren()
local configCols = {}
for i = 1, 2 do
    configCols[i] = New("Frame", { Parent = configContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = configCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
-- Keep every page clear of the 240px sidebar.  The old 264px inset was
-- too small on narrow viewports and some cards visually crossed into the nav.
content.Position = UDim2.fromOffset(282, 104); content.Size = UDim2.new(1, -306, 1, -128); content.Visible = false
configContent.Position = content.Position; configContent.Size = content.Size
local visualContent = content:Clone(); visualContent.Name = "VisualContent"; visualContent.Parent = win; visualContent.Visible = false; visualContent:ClearAllChildren()
local visualCols = {}
for i = 1, 2 do
    visualCols[i] = New("Frame", { Parent = visualContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = visualCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local mainContent = content:Clone(); mainContent.Name = "MainContent"; mainContent.Parent = win; mainContent.Visible = false; mainContent:ClearAllChildren()
local mainCols = {}
for i = 1, 2 do
    mainCols[i] = New("Frame", { Parent = mainContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = mainCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end
local worldContent = content:Clone(); worldContent.Name = "WorldContent"; worldContent.Parent = win; worldContent.Visible = false; worldContent:ClearAllChildren()
local worldCols = {}
for i = 1, 2 do
    worldCols[i] = New("Frame", { Parent = worldContent, Position = UDim2.new((i - 1) * .5, (i - 1) * 10, 0, 0), Size = UDim2.new(.5, -10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    New("UIListLayout", { Parent = worldCols[i], Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
end

local dashboard = New("Frame", { Parent = win, Position = content.Position, Size = content.Size, BackgroundTransparency = 1 })
-- profile card
local profile = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(430, 168), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(profile, 18); stroke(profile, C.border, .5)
local avatar = New("ImageLabel", { Parent = profile, Position = UDim2.fromOffset(22, 24), Size = UDim2.fromOffset(120, 120), BackgroundColor3 = C.surface })
corner(avatar, 20); stroke(avatar, C.border, .45)
task.spawn(function()
    local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
    if ok then avatar.Image = img end
end)
text(profile, LocalPlayer.DisplayName, 24, UDim2.fromOffset(162, 32))
text(profile, "@" .. LocalPlayer.Name, 15, UDim2.fromOffset(163, 70), true)
local pill = New("Frame", { Parent = profile, Position = UDim2.fromOffset(162, 104), Size = UDim2.fromOffset(158, 30), BackgroundColor3 = C.accent, BackgroundTransparency = .8 })
corner(pill, 15); stroke(pill, C.accent, .35)
local pillDot = New("Frame", { Parent = pill, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent }); corner(pillDot, 4)
text(pill, "Connected", 13, UDim2.fromOffset(26, 7))
-- hero card
local heroCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(446, 0), Size = UDim2.new(1, -446, 0, 168), BackgroundColor3 = C.card, BackgroundTransparency = .15 })
corner(heroCard, 18); stroke(heroCard, C.border, .45)
New("UIGradient", { Parent = heroCard, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(23,28,25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,12,14)) }), Rotation = 25 })
text(heroCard, "NOIR SILENT AIM", 26, UDim2.fromOffset(26, 24))
text(heroCard, "v4 \u{2022} gun & knife prediction, player and object ESP, presets", 14, UDim2.fromOffset(27, 62), true)
local statText = text(heroCard, "", 14, UDim2.fromOffset(27, 96), true)
-- stat cards
local fpsCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(fpsCard, 18); stroke(fpsCard, C.border, .5)
text(fpsCard, "FPS", 14, UDim2.fromOffset(22, 20), true)
local fpsText = text(fpsCard, "60", 42, UDim2.fromOffset(22, 50)); fpsText.TextColor3 = C.text
local pingCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(303, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(pingCard, 18); stroke(pingCard, C.border, .5)
text(pingCard, "NETWORK LATENCY", 14, UDim2.fromOffset(22, 20), true)
local pingText = text(pingCard, "-- ms", 42, UDim2.fromOffset(22, 50)); pingText.TextColor3 = C.text
local playerCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(606, 184), Size = UDim2.fromOffset(286, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .25 })
corner(playerCard, 18); stroke(playerCard, C.border, .5)
text(playerCard, "PLAYERS", 14, UDim2.fromOffset(22, 20), true)
local playerText = text(playerCard, "0", 42, UDim2.fromOffset(22, 50)); playerText.TextColor3 = C.text
-- info card
local infoCard = New("Frame", { Parent = dashboard, Position = UDim2.fromOffset(0, 332), Size = UDim2.new(1, 0, 1, -348), BackgroundColor3 = C.panel, BackgroundTransparency = .3 })
corner(infoCard, 18); stroke(infoCard, C.border, .5)
text(infoCard, "QUICK START", 18, UDim2.fromOffset(24, 22))
text(infoCard, "Open Combat for silent aim, World for gun & fling tools, Visuals for ESP.", 14, UDim2.fromOffset(25, 54), true)
text(infoCard, "Settings are saved automatically to NOIR.CONFIG.", 14, UDim2.fromOffset(25, 78), true)
local frameCounter, lastFps = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCounter += 1
    local now = os.clock()
    if now - lastFps >= 1 then
        fpsText.Text = tostring(math.floor(frameCounter / (now - lastFps) + .5))
        frameCounter = 0; lastFps = now
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingText.Text = ok and (tostring(math.floor(v + .5)) .. " ms") or "-- ms"
        local pl = #Players:GetPlayers()
        playerText.Text = tostring(pl)
        statText.Text = "Loaded \u{2022} " .. tostring(pl) .. " players in server"
    end
end)

-- (navigation now lives in the left sidebar; the old bottom bar was removed)
local activePage = "home"
local selectPage
do
    local pageObjects = { home = dashboard, main = mainContent, aim = content, world = worldContent, visual = visualContent }
    local pageBasePosition = content.Position
    local pageTransitionId = 0
    local function pageScaleFor(object)
        local scaler = object:FindFirstChild("NoirPageScale")
        if not scaler then scaler = New("UIScale", { Name = "NoirPageScale", Scale = 1, Parent = object }) end
        return scaler
    end
    function selectPage(page)
        if not pageObjects[page] then page = "home" end
        pageTransitionId += 1
        local transitionId = pageTransitionId
        local oldPage = activePage
        local oldObject = pageObjects[oldPage]
        local newObject = pageObjects[page]
        activePage = page

        -- Pages used to slide horizontally during every navigation change.
        -- If two transitions overlapped, an old tween could finish later and
        -- leave the whole section column a few pixels to the left.  Keep one
        -- immutable horizontal anchor and animate only scale/visibility.
        for _, object in pairs(pageObjects) do
            if object ~= oldObject and object ~= newObject then
                object.Visible = false
                object.Position = pageBasePosition
                pageScaleFor(object).Scale = 1
            end
        end
        if oldObject and oldObject ~= newObject and oldObject.Visible then
            local oldScale = pageScaleFor(oldObject)
            oldObject.Position = pageBasePosition
            TweenService:Create(oldScale, TweenInfo.new(.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = .96 }):Play()
            task.delay(.18, function()
                if transitionId == pageTransitionId and oldObject ~= pageObjects[activePage] then
                    oldObject.Visible = false
                    oldObject.Position = pageBasePosition
                    oldScale.Scale = 1
                end
            end)
        end
        if newObject then
            local newScale = pageScaleFor(newObject)
            newObject.Position = pageBasePosition
            if newObject:IsA("ScrollingFrame") then
                newObject.CanvasPosition = Vector2.new(0, newObject.CanvasPosition.Y)
            end
            newScale.Scale = .94
            newObject.Visible = true
            TweenService:Create(newScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
        configContent.Visible = false
        for name, b in pairs(navButtons) do
            local active = name == page
            TweenService:Create(b, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = active and C.card or C.surface, BackgroundTransparency = active and 0 or 1 }):Play()
            local data = navIcons[name]
            if data then
                TweenService:Create(data.icon, TweenInfo.new(.2), { ImageColor3 = active and C.accent or C.dim }):Play()
                TweenService:Create(data.label, TweenInfo.new(.2), { TextColor3 = active and C.text or C.dim }):Play()
                TweenService:Create(data.bar, TweenInfo.new(.2), { BackgroundTransparency = active and 0 or 1 }):Play()
            end
        end
    end
end
for name, b in pairs(navButtons) do b.MouseButton1Click:Connect(function() if activePage == name then selectPage("home") else selectPage(name) end end) end
selectPage("home")

--====================================================== SECTION BUILDER
local sectionCount, mainSectionCount, worldSectionCount, visualSectionCount, configSectionCount = 0, 0, 0, 0, 0
local sectionPanels, controls = {}, {}
function refreshCanvas()
    task.defer(function()
        content.CanvasSize = UDim2.fromOffset(0, math.max(cols[1].AbsoluteSize.Y, cols[2].AbsoluteSize.Y) + 165)
        configContent.CanvasSize = UDim2.fromOffset(0, math.max(configCols[1].AbsoluteSize.Y, configCols[2].AbsoluteSize.Y) + 165)
        visualContent.CanvasSize = UDim2.fromOffset(0, math.max(visualCols[1].AbsoluteSize.Y, visualCols[2].AbsoluteSize.Y) + 165)
        mainContent.CanvasSize = UDim2.fromOffset(0, math.max(mainCols[1].AbsoluteSize.Y, mainCols[2].AbsoluteSize.Y) + 165)
        worldContent.CanvasSize = UDim2.fromOffset(0, math.max(worldCols[1].AbsoluteSize.Y, worldCols[2].AbsoluteSize.Y) + 130)
    end)
end
search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(search.Text or "")
    local counts = { main = 0, aim = 0, world = 0, visual = 0 }
    for _, entry in ipairs(sectionPanels) do
        local hay = entry.name
        for _, d in ipairs(entry.panel:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then hay = hay .. " " .. string.lower(d.Text or "") end
        end
        local match = q == "" or string.find(hay, q, 1, true) ~= nil
        entry.panel.Visible = match
        if match then counts[entry.page] = (counts[entry.page] or 0) + 1 end
    end
    if q ~= "" and activePage ~= "home" and (counts[activePage] or 0) == 0 then
        for _, page in ipairs({ "main", "aim", "world", "visual" }) do if counts[page] > 0 then selectPage(page) break end end
    end
    refreshCanvas()
end)

local host = {}

-- Notifications live in their own right-side rail instead of being created at
-- the same bottom-right pixel position.  This prevents a stack of toasts from
-- covering the window, the round timer, or the shoot button.
local notificationHolder = New("Frame", {
    Parent = gui, Name = "NotificationRail", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -20, 0, 82), Size = UDim2.new(0, 360, 0, 270),
    BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 1000,
})
local notificationLayout = New("UIListLayout", {
    Parent = notificationHolder, Padding = UDim.new(0, 9),
    FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
})
local notificationSerial = 0
local activeNotifications = {}
local function trimNotifications()
    while #activeNotifications > 3 do
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
end
function host.Notify(title, duration)
    notificationSerial += 1
    local life = math.max(1.5, tonumber(duration) or 3)
    local card = New("Frame", {
        Parent = notificationHolder, Name = "Toast_" .. tostring(notificationSerial),
        Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.panel,
        BackgroundTransparency = .04, BorderSizePixel = 0, LayoutOrder = notificationSerial,
        ZIndex = 1000,
    })
    corner(card, 14); stroke(card, C.accent, .18)
    New("Frame", { Parent = card, Position = UDim2.fromOffset(0, 13), Size = UDim2.fromOffset(3, 50),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    local badge = New("TextLabel", { Parent = card, Position = UDim2.fromOffset(18, 9), Size = UDim2.new(1, -30, 0, 17),
        BackgroundTransparency = 1, Text = "NOIR  •  NOTIFICATION", TextColor3 = C.accent2,
        TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001 })
    local message = New("TextLabel", { Parent = card, Position = UDim2.fromOffset(18, 29), Size = UDim2.new(1, -30, 0, 30),
        BackgroundTransparency = 1, Text = tostring(title), TextColor3 = C.text,
        TextSize = 14, Font = Enum.Font.Gotham, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 1001 })
    local progress = New("Frame", { Parent = card, Position = UDim2.fromOffset(18, 69), Size = UDim2.new(1, -30, 0, 2),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    table.insert(activeNotifications, card); trimNotifications()
    TweenService:Create(progress, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(life, function()
        for i = #activeNotifications, 1, -1 do
            if activeNotifications[i] == card then table.remove(activeNotifications, i) break end
        end
        if card.Parent then
            local out = TweenService:Create(card, TweenInfo.new(.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 24, 0, 0), BackgroundTransparency = 1,
            })
            out:Play(); out.Completed:Connect(function() if card.Parent then card:Destroy() end end)
        end
    end)
end
function host.CreateTab()
    local tab = {}
    function tab:AddSection(name, description)
        local isConfig = name == "NOIR CONFIG"
        local isVisual = name == "Visuals" or name == "Object ESP" or string.find(name, "VISUAL", 1, true) == 1
        local isMain = string.sub(name, 1, 5) == "MAIN "
        local isWorld = string.sub(name, 1, 6) == "WORLD "
        local col, page = nil, "aim"
        if isVisual then visualSectionCount += 1; col = visualCols[(visualSectionCount - 1) % 2 + 1]; page = "visual"
        elseif isMain then mainSectionCount += 1; col = mainCols[(mainSectionCount - 1) % 2 + 1]; page = "main"
        elseif isWorld then worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "world"
        else sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1] end
        local panel = New("Frame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .25, ClipsDescendants = true })
        corner(panel, 18); stroke(panel, C.border, .5)
        local tick = New("Frame", { Parent = panel, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 20), BackgroundColor3 = C.accent })
        corner(tick, 2)
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. " " .. (description or "")) })
        local shownName = name:gsub("^MAIN \u{2022} ", ""):gsub("^WORLD \u{2022} ", ""):gsub("^VISUAL \u{2022} ", "")
        text(panel, shownName, 18, UDim2.fromOffset(24, 16))
        if description and description ~= "" then text(panel, description, 12, UDim2.fromOffset(24, 44), true) end
        local holder = New("Frame", { Parent = panel, Position = UDim2.fromOffset(20, description ~= "" and 74 or 57), Size = UDim2.new(1, -40, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        New("UIListLayout", { Parent = holder, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })
        New("UIPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
        holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCanvas); refreshCanvas()
        local api = { Name = name }
        local storagePrefix = name .. "::"
        local function row(label, h)
            local r = New("Frame", { Parent = holder, Size = UDim2.new(1, 0, 0, h or 62), BackgroundTransparency = 1 })
            text(r, label, 16, UDim2.fromOffset(0, 10))
            return r
        end
        function api:AddToggle(label, callback)
            local savedToggle = NoirPersistence.data.toggles[storagePrefix .. label]
            if savedToggle == nil and NoirPersistence.safeLegacy[label] then
                savedToggle = NoirPersistence.data.toggles[label]
                if savedToggle ~= nil then NoirPersistence.data.toggles[storagePrefix .. label] = savedToggle; NoirPersistence.Save() end
            end
            local state = savedToggle == true
            local r = row(label, 52)
            local pill = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(64, 34),
                BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
            corner(pill, 17); stroke(pill, C.border, .55)
            local dot = New("Frame", { Parent = pill, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromRGB(150,155,162) })
            corner(dot, 13)
            local function set(v, persist)
                state = v == true
                TweenService:Create(pill, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = state and C.accent or C.off }):Play()
                TweenService:Create(dot, TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = state and UDim2.fromOffset(34, 4) or UDim2.fromOffset(4, 4), BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(150,155,162), Size = UDim2.fromOffset(30, 30) }):Play()
                task.delay(.20, function() if dot.Parent then TweenService:Create(dot, TweenInfo.new(.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(26, 26) }):Play() end end)
                callback(state)
                if persist ~= false then NoirPersistence.data.toggles[storagePrefix .. label] = state; NoirPersistence.Save() end
            end
            pill.MouseButton1Click:Connect(function() set(not state, true) end)
            set(state, false)
            return function(v) set(v == nil and not state or v, true) end
        end
        function api:AddButton(label, callback)
            local b = New("TextButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.btn,
                Text = label, TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(b, 12); stroke(b, C.border, .5)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = Color3.fromRGB(48,52,56) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundColor3 = C.btn }):Play() end)
            b.MouseButton1Click:Connect(callback)
            return b
        end
        function api:AddSlider(label, min, max, default, callback)
            local savedSlider = NoirPersistence.data.sliders[storagePrefix .. label]
            if savedSlider == nil then
                savedSlider = NoirPersistence.data.sliders[label]
                if savedSlider ~= nil then NoirPersistence.data.sliders[storagePrefix .. label] = savedSlider; NoirPersistence.Save() end
            end
            default = tonumber(savedSlider) or default
            local r = row(label, 68)
            local value = New("TextBox", { Parent = r, Position = UDim2.new(1, -72, 0, 5), Size = UDim2.fromOffset(72, 30), BackgroundColor3 = C.surface,
                BackgroundTransparency = .12, Text = tostring(default), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false })
            corner(value, 9); stroke(value, C.border, .4)
            local track = New("Frame", { Parent = r, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.off })
            corner(track, 3)
            local fill = New("Frame", { Parent = track, Size = UDim2.fromScale((default - min) / (max - min), 1), BackgroundColor3 = C.accent })
            corner(fill, 3)
            local knob = New("Frame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - min) / (max - min), 0, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.text })
            corner(knob, 7); stroke(knob, C.border, .3)
            local current = default
            local function set(v, persist)
                current = math.clamp(math.floor((tonumber(v) or current or default) + .5), min, max)
                fill.Size = UDim2.fromScale((current - min) / (max - min), 1)
                knob.Position = UDim2.new((current - min) / (max - min), 0, .5, 0)
                value.Text = tostring(current)
                callback(current)
                if persist ~= false then NoirPersistence.data.sliders[storagePrefix .. label] = current; NoirPersistence.Save() end
            end
            set(default, false)
            value.FocusLost:Connect(function() set(value.Text) end)
            local drag = false
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                    set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
            return { SetValue = function(_, v) set(v) end, GetValue = function() return current end }
        end
        function api:AddDropdown(label, values, callback)
            local r = row(label, 56)
            local idx = table.find(values, NoirPersistence.data.dropdowns[storagePrefix .. label]) or 1
            local b = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(190, 42),
                BackgroundColor3 = C.surface, Text = tostring(values[1] or "None") .. "  \u{2304}", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 5 })
            corner(b, 10); stroke(b)
            local popup
            local function close() if popup then popup:Destroy(); popup = nil end end
            local function set(v)
                local found = table.find(values, v)
                if found then idx = found end
                b.Text = tostring(values[idx] or "None") .. "  \u{2304}"
                if values[idx] ~= nil then callback(values[idx]); NoirPersistence.data.dropdowns[storagePrefix .. label] = values[idx]; NoirPersistence.Save() end
            end
            local function open()
                close()
                popup = New("ScrollingFrame", { Parent = gui, Position = UDim2.fromOffset(b.AbsolutePosition.X / scale.Scale, (b.AbsolutePosition.Y + b.AbsoluteSize.Y + 4) / scale.Scale),
                    Size = UDim2.fromOffset(b.AbsoluteSize.X / scale.Scale, math.min(#values * 38, 190)), CanvasSize = UDim2.fromOffset(0, #values * 38),
                    BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 4, ZIndex = 50 })
                corner(popup, 10); stroke(popup, C.accent, .2)
                New("UIListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
                for _, v in ipairs(values) do
                    local item = New("TextButton", { Parent = popup, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = tostring(v),
                        TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 51 })
                    item.MouseButton1Click:Connect(function() set(v); close() end)
                end
            end
            b.MouseButton1Click:Connect(function() if popup then close() else open() end end)
            local ctl = {}
            function ctl:SetValue(v) set(v) end
            function ctl:Select(v) set(v) end
            function ctl:Refresh(newValues, selected) values = newValues or {}; idx = 1; set(selected or values[1]) end
            return ctl
        end
        function api:AddTextBox(label, callback)
            local r = row(label, 64)
            local box = New("TextBox", { Parent = r, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.surface,
                Text = "", PlaceholderText = label, TextColor3 = C.text, PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
            corner(box, 9); stroke(box)
            box.FocusLost:Connect(function() callback(box.Text) end)
            return { SetValue = function(_, v) box.Text = tostring(v) end }
        end
        function api:AddLabel(label)
            local r = row(label, 44)
            local labelObject = r:FindFirstChildWhichIsA("TextLabel")
            return { SetValue = function(_, value) if labelObject and labelObject.Parent then labelObject.Text = tostring(value) end end,
                GetValue = function() return labelObject and labelObject.Text or "" end,
                Instance = r }
        end
        function api:AddParagraph(title, body)
            local r = row(tostring(title or ""), 68)
            if body and tostring(body) ~= "" then
                local detail = text(r, tostring(body), 12, UDim2.fromOffset(0, 32), true)
                detail.TextWrapped = true
                detail.Size = UDim2.new(1, 0, 0, 30)
            end
            return r
        end
        -- Compatibility surface for embedded ODH plugins. The current
        -- plugins do not require a colour picker, but exposing a small
        -- SetRGBValue-compatible control keeps their adapter API intact.
        function api:AddColorpicker(label, default, callback)
            local r = row(label, 52)
            local colour = default or C.accent
            local swatch = New("Frame", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(64, 34), BackgroundColor3 = colour })
            corner(swatch, 10); stroke(swatch)
            if callback then callback(colour) end
            return { SetRGBValue = function(_, value) if typeof(value) == "Color3" then colour = value; swatch.BackgroundColor3 = value; if callback then callback(value) end end end,
                GetValue = function() return colour end }
        end
        function api:AddKeybind(label, default, callback)
            local savedKey = NoirPersistence.data.keybinds[storagePrefix .. label] or default
            local r = row(label, 52)
            local btn = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(130, 34),
                BackgroundColor3 = C.surface, Text = tostring(savedKey), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(btn, 10); stroke(btn)
            local listening, currentKey, conn = false, savedKey, nil
            btn.MouseButton1Click:Connect(function()
                listening = true; btn.Text = "Press a key..."
                if conn then conn:Disconnect() end
                conn = UIS.InputBegan:Connect(function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[storagePrefix .. label] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        currentKey = "MouseButton1"; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[storagePrefix .. label] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    end
                end)
            end)
            return { SetValue = function(_, v) currentKey = v; btn.Text = tostring(v) end, GetValue = function() return currentKey end }
        end
        return api
    end
    return tab
end

--============================================================= CONFIG
local config = {
    -- gun / silent aim
    enabled = false,
    targetMode = "Murderer",          -- Murderer | Sheriff | Hero | Nearest | Selected | Crosshair | Lowest Health | Random
    hitPart = "HumanoidRootPart",     -- Head | HumanoidRootPart | UpperTorso | LowerTorso | Torso | Random
    fovSize = 0,                      -- 0 = disabled
    showFov = false,
    aimKey = "None",                  -- hold to aim (None = always active)
    toggleKey = "None",
    autoFire = false,
    autoFireKey = "None",
    shotMethod = "Remote",            -- Remote = Vector3/CFrame remote rewrite; CFrame = only CFrame protocol
    wallCheck = false,
    ignoreDead = true,
    ignoreFriends = false,
    maxDistance = 0,                  -- 0 = unlimited
    -- prediction
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    maxLead = 0.18,
    targetPart = "HumanoidRootPart",
    alignDirection = true,
    prioritizePing = true,
    predictJump = false,
    predictLag = true,
    maxSimulationMs = 180,
    predictionIntervalMs = 72,
    manualPingMs = 80,
    offsetX = 0, offsetY = 0, offsetZ = 0,
    horizontalMultiplier = 100, verticalMultiplier = 100,
    -- knife
    knifeEnabled = false,
    knifeWallCheck = false,
    knifePrioritizeSheriff = true,
    knifeAutoThrow = false,
    -- player ESP
    espOutline = false, espOutlineMurderer = false, espOutlineSheriff = false,
    espChams = false, espChamsMurderer = false, espChamsSheriff = false,
    espBox = false, espBoxMurderer = false, espBoxSheriff = false,
    espName = false, espDistance = false, espHealth = false, espRole = false,
    espTracer = false, espSkeleton = false,
    -- object ESP
    outlineDroppedGun = false, outlineTraps = false, outlineThrowingKnives = false, outlineCoins = false,
    boxDroppedGun = false, boxTraps = false, boxThrowingKnives = false, boxCoins = false,
    -- misc
    showShootButton = false,
    lockShootButton = false,
    selectedPlayer = nil,
}

--============================================================== STATE
local murderer, sheriff, hero
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton, shootGui, shootBusy = nil, nil, false
local presetName = "default"
local PRESET_FOLDER = "NOIR.CONFIG"
local revertControls, revertToggleStates, syncRevertControls = {}, {}, nil
local presetDropdown
local motionPart, motionPosition, motionTime
local measuredVelocity = Vector3.zero
local motionSamples = {}
local previousEstimatedVelocity = Vector3.zero
local estimatedAcceleration = Vector3.zero
local lastAutoTune = 0
local roundTimerEndsAt, roundPendingStart
-- waiting/starting/playing is also used to gate gun automation.  Without a
-- round state, the lobby can look like a valid GunDrop and the old loop keeps
-- retrying forever after the local player has died.
local roundState = "waiting"
local roundResetToken = 0
local lastRoundResetAt = os.clock()
local instantRoleDetection = false
local autoNotifyRoles = false
local announcedRoles = {}
local roleCache = {}
local playerData = {}
local aimHeld = true
local autoFireHeld = false

--===================================================== PERFORMANCE CACHE
-- Cached player list: avoids allocating a fresh table every frame in hot loops.
local cachedPlayers = {}
local function refreshPlayerCache() cachedPlayers = Players:GetPlayers() end
refreshPlayerCache()
local function getPlayers() return cachedPlayers end
Players.PlayerAdded:Connect(refreshPlayerCache)
Players.PlayerRemoving:Connect(refreshPlayerCache)

--============================================================ HELPERS
function notify(msg, time)
    if type(host.Notify) == "function" then pcall(host.Notify, "MM2 Silent Aim: " .. tostring(msg), time or 3) end
end
function validTarget(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return player ~= nil and player ~= LocalPlayer and character ~= nil and humanoid ~= nil and humanoid.Health > 0
end
function localCharacter() return LocalPlayer.Character end
-- Cache the local humanoid / root per character so hot loops don't re-run FindFirstChild every call.
local localHumCache, localHumChar
function localHumanoid()
    local c = LocalPlayer.Character
    if c ~= localHumChar then
        localHumChar = c
        localHumCache = c and c:FindFirstChildWhichIsA("Humanoid")
    end
    return localHumCache
end
local localRootCache, localRootChar
function localRoot()
    local c = LocalPlayer.Character
    if c ~= localRootChar then
        localRootChar = c
        localRootCache = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
    end
    return localRootCache
end
function playerHasTool(player, toolName)
    local character = player and player.Character
    local backpack = player and player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end
-- Friend status rarely changes mid-session, so cache the IsFriendsWith result per player.
local friendCache = {}
Players.PlayerRemoving:Connect(function(p) friendCache[p] = nil end)
function isFriend(player)
    if not config.ignoreFriends or player == nil then return false end
    local cached = friendCache[player]
    if cached ~= nil then return cached end
    local ok, res = pcall(function() return player:IsFriendsWith(LocalPlayer.UserId) end)
    local value = (ok and res == true)
    friendCache[player] = value
    return value
end
function distanceTo(player)
    local root = localRoot()
    local t = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and t then return (t.Position - root.Position).Magnitude end
    return math.huge
end

--========================================================== ROLE ENGINE
local ESP_INACTIVE_COLOR = Color3.fromRGB(150, 154, 162)
function roleColor(role)
    if role == "murderer" then return Color3.fromRGB(255, 55, 65) end
    if role == "sheriff" then return Color3.fromRGB(55, 145, 255) end
    if role == "hero" then return Color3.fromRGB(255, 220, 45) end
    return Color3.fromRGB(65, 235, 105)
end
local function playerIsInLobby(player)
    if not player then return true end
    local teamName = player.Team and string.lower(tostring(player.Team.Name)) or ""
    if string.find(teamName, "lobby", 1, true)
        or string.find(teamName, "spectat", 1, true)
        or string.find(teamName, "observer", 1, true)
        or string.find(teamName, "waiting", 1, true) then
        return true
    end

    -- MM2 builds have used both attributes and BoolValues for spectators/dead
    -- players. Check only objects that actually exist; do not assume a single
    -- hierarchy so active players remain coloured normally.
    local containers = { player, player.Character }
    for _, container in ipairs(containers) do
        if container then
            for key, value in pairs(container:GetAttributes()) do
                local k = string.lower(tostring(key))
                if (string.find(k, "inround", 1, true) or string.find(k, "ingame", 1, true)
                    or string.find(k, "isplaying", 1, true) or string.find(k, "alive", 1, true))
                    and value == false then
                    return true
                end
                if string.find(k, "state", 1, true) or string.find(k, "status", 1, true)
                    or string.find(k, "location", 1, true) or string.find(k, "place", 1, true) then
                    local textValue = string.lower(tostring(value))
                    if string.find(textValue, "lobby", 1, true)
                        or string.find(textValue, "spectat", 1, true)
                        or string.find(textValue, "dead", 1, true)
                        or string.find(textValue, "waiting", 1, true) then
                        return true
                    end
                end
            end
            for _, name in ipairs({ "InLobby", "Spectating", "Dead", "IsDead" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and flag.Value then return true end
            end
            for _, name in ipairs({ "InRound", "InGame", "IsPlaying", "Alive", "IsAlive" }) do
                local flag = container:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and not flag.Value then return true end
            end
        end
    end
    return false
end
function playerESPInactive(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    -- Gray applies to the lobby/spectator player individually even while a
    -- different player is still in an active round.
    return playerIsInLobby(player)
        or (roundState ~= "starting" and roundState ~= "playing")
        or not humanoid or humanoid.Health <= 0
end
function playerESPColor(player, role)
    return playerESPInactive(player) and ESP_INACTIVE_COLOR or roleColor(role)
end
function espPlayerRole(player)
    local cached = player and roleCache[player.UserId]
    if cached == "murderer" or cached == "sheriff" or cached == "hero" or cached == "innocent" then return cached end
    if playerHasTool(player, "Knife") then return "murderer" end
    if playerHasTool(player, "Gun") then return "sheriff" end
    return "innocent"
end
function setTarget(player)
    if not validTarget(player) then player = nil end
    if murderer ~= player then
        murderer = player
        if player then notify("Target: " .. player.Name, 2) end
    end
end
function findByKnife()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "Knife") then return player end
    end
end
function findByGun()
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and playerHasTool(player, "Gun") then return player end
    end
end
function consumeData(data)
    if typeof(data) ~= "table" then return false end
    local foundMurderer, foundSheriff, foundHero
    local rolesChanged = false
    for _, player in ipairs(getPlayers()) do
        local info = data[player.Name] or data[tostring(player.UserId)]
        if typeof(info) == "table" then
            playerData[player.UserId] = info
            local role = info.Role or info.role or info.CurrentRole
            local normalized = string.lower(tostring(role or "innocent"))
            local resolved
            if normalized == "murderer" then resolved = "murderer"; foundMurderer = player
            elseif normalized == "sheriff" then resolved = "sheriff"; foundSheriff = player
            elseif normalized == "hero" then resolved = "hero"; foundHero = player
            else resolved = "innocent" end
            if roleCache[player.UserId] ~= resolved then
                rolesChanged = true
                roleCache[player.UserId] = resolved
                if autoNotifyRoles and resolved ~= "innocent" and announcedRoles[player.UserId] ~= resolved then
                    announcedRoles[player.UserId] = resolved
                    notify(player.Name .. " is " .. string.upper(resolved), 5)
                end
            end
        elseif typeof(info) == "string" then
            local normalized = string.lower(info)
            local resolved = normalized == "murderer" and "murderer" or normalized == "sheriff" and "sheriff" or normalized == "hero" and "hero" or "innocent"
            if normalized == "murderer" then foundMurderer = player
            elseif normalized == "sheriff" then foundSheriff = player
            elseif normalized == "hero" then foundHero = player end
            if roleCache[player.UserId] ~= resolved then roleCache[player.UserId] = resolved; rolesChanged = true end
        end
    end
    sheriff = foundSheriff or sheriff
    hero = foundHero or hero
    if foundMurderer then
        setTarget(foundMurderer)
    end
    if rolesChanged then
        if type(refreshESP) == "function" then refreshESP() end
    end
    return foundMurderer ~= nil
end
local playerDataRemote
function getPlayerDataRemote()
    if playerDataRemote and playerDataRemote.Parent then return playerDataRemote end
    local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    playerDataRemote = (remote and remote:IsA("RemoteFunction")) and remote or nil
    return playerDataRemote
end
function refreshTarget()
    local weaponTarget = findByKnife()
    if weaponTarget then
        setTarget(weaponTarget)
        return
    end
    local remote = getPlayerDataRemote()
    if remote then
        local ok, data = pcall(function() return remote:InvokeServer() end)
        if ok and consumeData(data) then return end
    end
    setTarget(nil)
end
function updatePing()
    pcall(function()
        local network = Stats:FindFirstChild("Network")
        local items = network and network:FindFirstChild("ServerStatsItem")
        local pingItem = items and items:FindFirstChild("Data Ping")
        if pingItem then
            local measured = pingItem:GetValue() / 1000
            if measured > 0 and measured < 2 then cachedPing = cachedPing * 0.7 + measured * 0.3 end
        end
    end)
end

--=============================================================== ESP
local ESP_OUTLINE_NAME = "NoirESPOutline"
local ESP_BOX_NAME = "NoirESPBox"
local espTracers = {}
local espRefs = {}          -- [player] = { char, info, bar, humanoid } cached billboard refs
local Drawing = (typeof(Drawing) == "table") and Drawing or nil

function clearESPCharacter(character)
    if not character then return end
    local outline = character:FindFirstChild(ESP_OUTLINE_NAME)
    if outline then outline:Destroy() end
    for _, item in ipairs(character:GetDescendants()) do
        if item.Name == ESP_BOX_NAME or item.Name == "NoirESPRole" or item.Name == "NoirESPBar" then item:Destroy() end
    end
end
function makeBillboard(root, role)
    local box = Instance.new("BillboardGui")
    box.Name = ESP_BOX_NAME
    box.Adornee = root
    box.AlwaysOnTop = true
    box.LightInfluence = 0
    box.Size = UDim2.fromOffset(96, 132)
    box.StudsOffset = Vector3.new(0, 2.4, 0)
    box.Parent = root
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromScale(1, 1)
    frame.Parent = box
    local line = Instance.new("UIStroke")
    line.Color = roleColor(role)
    line.Thickness = 1.6
    line.Transparency = 0
    line.Parent = frame
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    -- health bar
    local barBg = Instance.new("Frame")
    barBg.Name = "NoirESPBar"
    barBg.AnchorPoint = Vector2.new(0, 1)
    barBg.Position = UDim2.new(0, -6, 1, 0)
    barBg.Size = UDim2.new(0, 4, 1, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0, 0, 1, 0)
    bar.Size = UDim2.fromScale(1, 1)
    bar.BackgroundColor3 = Color3.fromRGB(65, 235, 105)
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    -- name / distance / role
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NoirESPName"
    nameLabel.BackgroundTransparency = 1
    nameLabel.AnchorPoint = Vector2.new(.5, 1)
    nameLabel.Position = UDim2.new(.5, 0, 0, -2)
    nameLabel.Size = UDim2.new(1, 120, 0, 16)
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = .3
    nameLabel.Text = ""
    nameLabel.Parent = frame
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "NoirESPRole"
    infoLabel.BackgroundTransparency = 1
    infoLabel.AnchorPoint = Vector2.new(.5, 0)
    infoLabel.Position = UDim2.new(.5, 0, 1, 2)
    infoLabel.Size = UDim2.new(1, 120, 0, 15)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.TextColor3 = roleColor(role)
    infoLabel.TextStrokeTransparency = .3
    infoLabel.Text = ""
    infoLabel.Parent = frame
    return box, nameLabel, infoLabel, bar, line
end
function applyESPPlayer(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then espRefs[player] = nil return end
    clearESPCharacter(character)
    espRefs[player] = nil
    local role = espPlayerRole(player)
    local displayColor = playerESPColor(player, role)
    local outlineWanted = config.espOutline or (config.espOutlineMurderer and role == "murderer") or (config.espOutlineSheriff and role == "sheriff")
    local chamsWanted = config.espChams or (config.espChamsMurderer and role == "murderer") or (config.espChamsSheriff and role == "sheriff")
    local boxWanted = config.espBox or (config.espBoxMurderer and role == "murderer") or (config.espBoxSheriff and role == "sheriff")
    local textWanted = config.espName or config.espDistance or config.espHealth or config.espRole
    local highlight
    local boxStroke
    if outlineWanted or chamsWanted then
        highlight = Instance.new("Highlight")
        highlight.Name = ESP_OUTLINE_NAME
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = chamsWanted and .45 or 1
        highlight.FillColor = displayColor
        highlight.OutlineTransparency = outlineWanted and 0 or 1
        highlight.OutlineColor = displayColor
        highlight.Parent = character
    end
    if boxWanted or textWanted then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local box, nameLabel, infoLabel, bar, line = makeBillboard(root, role)
            boxStroke = line
            if not boxWanted then
                local frame = box:FindFirstChildOfClass("Frame")
                if frame then local s = frame:FindFirstChildOfClass("UIStroke"); if s then s.Transparency = 1 end end
            end
            if not config.espHealth and bar then bar.Parent.Visible = false end
            nameLabel.Visible = config.espName
            nameLabel.Text = player.Name
            infoLabel.Visible = config.espDistance or config.espRole
            infoLabel.TextColor3 = displayColor
            espRefs[player] = { char = character, info = infoLabel, bar = bar, humanoid = character:FindFirstChildWhichIsA("Humanoid"), highlight = highlight, boxStroke = boxStroke }
        end
    end
    -- Keep a reference even when only Highlight/Chams are enabled so the
    -- colour can change to gray immediately when the player dies.
    if not espRefs[player] then
        espRefs[player] = { char = character, info = nil, bar = nil, humanoid = character:FindFirstChildWhichIsA("Humanoid"), highlight = highlight, boxStroke = boxStroke }
    end
end
function refreshESP()
    for _, player in ipairs(getPlayers()) do applyESPPlayer(player) end
end
function bindESPPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function() task.wait(0.4); applyESPPlayer(player) end)
    if player.Character then applyESPPlayer(player) end
end
for _, player in ipairs(getPlayers()) do bindESPPlayer(player) end
Players.PlayerAdded:Connect(bindESPPlayer)

-- Highlight colours must react to Humanoid.Health and roundState changes even
-- when the character itself did not respawn.  This lightweight loop only
-- updates already-created ESP instances; it does not rescan the workspace.
task.spawn(function()
    while running do
        for _, player in ipairs(getPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local refs = espRefs[player]
                if character and (not refs or refs.char ~= character) then
                    applyESPPlayer(player)
                    refs = espRefs[player]
                end
                if character and refs and refs.char == character then
                    local role = espPlayerRole(player)
                    local color = playerESPColor(player, role)
                    if refs.highlight then
                        refs.highlight.FillColor = color
                        refs.highlight.OutlineColor = color
                    end
                    if refs.boxStroke then refs.boxStroke.Color = color end
                    if refs.info then refs.info.TextColor3 = color end
                end
            end
        end
        task.wait(.15)
    end
end)

-- tracer + skeleton render loop (optimized: precomputed bones, per-player cache, no per-frame string concat)
local R15_BONES = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
local R6_BONES = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"}, {"Torso","Left Leg"}, {"Torso","Right Leg"},
}
-- [player] = { char = character, parts = {{a,b},...}, lines = {line,...} }
local skeletonCache = {}

-- TTL cache for the tool-based role fallback (avoids tool lookups every frame).
local roleFallbackCache = {}
local function espRoleFast(player)
    local cached = roleCache[player.UserId]
    if cached then return cached end
    local now = os.clock()
    local entry = roleFallbackCache[player.UserId]
    if entry and now - entry.t < 0.5 then return entry.role end
    local role = espPlayerRole(player)
    roleFallbackCache[player.UserId] = { role = role, t = now }
    return role
end

local function newLine()
    if not Drawing then return nil end
    local line = Drawing.new("Line")
    line.Thickness = 1.4
    line.Transparency = 1
    line.Visible = false
    return line
end

local function hideAllESP()
    for _, line in pairs(espTracers) do line.Visible = false end
    for _, set in pairs(skeletonCache) do
        local lines = set.lines
        for i = 1, #lines do lines[i].Visible = false end
    end
end

local espLineAccum = 0
RunService.RenderStepped:Connect(function(dt)
    local wantTracer = config.espTracer
    local wantSkeleton = config.espSkeleton and Drawing
    if not wantTracer and not wantSkeleton then hideAllESP() return end
    if perfMode then
        espLineAccum += dt
        if espLineAccum < 0.033 then return end
        espLineAccum = 0
    end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local players = getPlayers()
    local viewport = cam.ViewportSize
    local bottom = Vector2.new(viewport.X / 2, viewport.Y)
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer then
            local character = player.Character
            local role = character and espRoleFast(player) or "innocent"
            local displayColor = playerESPColor(player, role)
            if wantTracer then
                local tracer = espTracers[player]
                if not tracer then tracer = newLine(); espTracers[player] = tracer end
                if tracer then
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local pos = cam:WorldToViewportPoint(root.Position)
                        tracer.From = bottom
                        tracer.To = Vector2.new(pos.X, pos.Y)
                        tracer.Color = displayColor
                        tracer.Visible = pos.Z > 0
                    else
                        tracer.Visible = false
                    end
                end
            else
                local tracer = espTracers[player]
                if tracer then tracer.Visible = false end
            end
            if wantSkeleton and character then
                local set = skeletonCache[player]
                if not set or set.char ~= character then
                    if set and set.lines then
                        for b = 1, #set.lines do if set.lines[b] then set.lines[b]:Remove() end end
                    end
                    local bones = character:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
                    set = { char = character, bones = bones, parts = {}, lines = {} }
                    for b = 1, #bones do
                        set.parts[b] = { character:FindFirstChild(bones[b][1]), character:FindFirstChild(bones[b][2]) }
                        set.lines[b] = newLine()
                    end
                    skeletonCache[player] = set
                end
                local parts, lines = set.parts, set.lines
                for b = 1, #lines do
                    local line = lines[b]
                    if line then
                        local pair = parts[b]
                        local a, b2 = pair[1], pair[2]
                        if a and b2 then
                            local pa = cam:WorldToViewportPoint(a.Position)
                            local pb = cam:WorldToViewportPoint(b2.Position)
                            line.From = Vector2.new(pa.X, pa.Y)
                            line.To = Vector2.new(pb.X, pb.Y)
                            line.Color = displayColor
                            line.Visible = pa.Z > 0 and pb.Z > 0
                        else
                            line.Visible = false
                        end
                    end
                end
            elseif skeletonCache[player] then
                local lines = skeletonCache[player].lines
                for b = 1, #lines do if lines[b] then lines[b].Visible = false end end
            end
        end
    end
end)

-- Clean up Drawing objects / refs when a player leaves so nothing leaks.
Players.PlayerRemoving:Connect(function(player)
    local set = skeletonCache[player]
    if set then
        for b = 1, #set.lines do if set.lines[b] then set.lines[b]:Remove() end end
        skeletonCache[player] = nil
    end
    local tracer = espTracers[player]
    if tracer then tracer:Remove(); espTracers[player] = nil end
    espRefs[player] = nil
    roleFallbackCache[player.UserId] = nil
end)

-- ESP text / health bar loop (throttled to ~12 Hz, uses cached billboard refs)
local espTextAccum = 0
RunService.RenderStepped:Connect(function(dt)
    if not (config.espDistance or config.espRole or config.espHealth) then return end
    espTextAccum += dt
    if espTextAccum < 0.08 then return end
    espTextAccum = 0
    local players = getPlayers()
    local showRole, showDist, showHealth = config.espRole, config.espDistance, config.espHealth
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer then
            local refs = espRefs[player]
            if refs and refs.char == player.Character then
                if refs.info and (showRole or showDist) then
                    local roleText = showRole and string.upper(espRoleFast(player)) or nil
                    local distText = showDist and (tostring(math.floor(distanceTo(player))) .. "m") or nil
                    if roleText and distText then refs.info.Text = roleText .. " | " .. distText
                    elseif roleText then refs.info.Text = roleText
                    else refs.info.Text = distText or "" end
                end
                if showHealth and refs.bar then
                    local hum = refs.humanoid
                    if not hum or hum.Parent ~= refs.char then hum = refs.char:FindFirstChildWhichIsA("Humanoid"); refs.humanoid = hum end
                    if hum then
                        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        refs.bar.Size = UDim2.fromScale(1, ratio)
                        refs.bar.BackgroundColor3 = playerESPInactive(player)
                            and ESP_INACTIVE_COLOR
                            or Color3.fromRGB(255 * (1 - ratio), 235 * ratio, 60)
                    end
                end
            end
        end
    end
end)

--====================================================== OBJECT ESP
function objectKind(instance)
    local name = string.lower(instance.Name)
    if string.find(name, "coin", 1, true) then return "coin" end
    if string.find(name, "trap", 1, true) then return "trap" end
    if name == "gundrop" or name == "gun" or string.find(name, "droppedgun", 1, true) or string.find(name, "gun_drop", 1, true) then return "gun" end
    if string.find(name, "knife", 1, true) and (string.find(name, "throw", 1, true) or not instance:FindFirstAncestorOfClass("Tool")) then return "knife" end
end
function objectPart(instance)
    if instance:IsA("BasePart") then return instance end
    if instance:IsA("Model") then return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true) end
    if instance:IsA("Tool") then return instance:FindFirstChildWhichIsA("BasePart", true) end
end
function objectEnabled(kind, box)
    if box then
        return kind == "coin" and config.boxCoins or kind == "trap" and config.boxTraps or kind == "gun" and config.boxDroppedGun or kind == "knife" and config.boxThrowingKnives
    end
    return kind == "coin" and config.outlineCoins or kind == "trap" and config.outlineTraps or kind == "gun" and config.outlineDroppedGun or kind == "knife" and config.outlineThrowingKnives
end
function objectColor(kind)
    if kind == "gun" then return Color3.fromRGB(70, 170, 255) end
    if kind == "coin" then return Color3.fromRGB(255, 220, 50) end
    return Color3.fromRGB(100, 255, 150)
end

-- Registry of highlighted objects: [instance] = { outline = Highlight, box = SelectionBox }.
-- Objects are added/removed incrementally (O(1) per DescendantAdded/Removing) instead of
-- re-scanning the whole workspace, which was the main source of freezes.
local objectESPRegistry = {}
function objectESPAnyEnabled()
    return config.outlineDroppedGun or config.outlineTraps or config.outlineThrowingKnives or config.outlineCoins
        or config.boxDroppedGun or config.boxTraps or config.boxThrowingKnives or config.boxCoins
end
function objectESPClearAll()
    for inst, entry in pairs(objectESPRegistry) do
        if entry.outline then entry.outline:Destroy() end
        if entry.box then entry.box:Destroy() end
    end
    table.clear(objectESPRegistry)
end
function addObjectESP(instance)
    local kind = objectKind(instance)
    if not kind then return end
    local part = objectPart(instance)
    if not part then return end
    if Players:GetPlayerFromCharacter(instance:FindFirstAncestorOfClass("Model")) then return end
    local entry = objectESPRegistry[instance]
    if not entry then entry = {}; objectESPRegistry[instance] = entry end
    if objectEnabled(kind, false) then
        if not entry.outline then
            local h = Instance.new("Highlight")
            h.Name = "NoirObjectOutline"; h.Adornee = instance; h.FillTransparency = 1
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = instance
            entry.outline = h
        end
        entry.outline.OutlineColor = objectColor(kind)
        entry.outline.OutlineTransparency = 0
    elseif entry.outline then
        entry.outline:Destroy(); entry.outline = nil
    end
    if objectEnabled(kind, true) then
        if not entry.box then
            local box = Instance.new("SelectionBox")
            box.Name = "NoirObjectBox"; box.Adornee = part; box.SurfaceTransparency = 1
            box.LineThickness = .04; box.Parent = part
            entry.box = box
        end
        entry.box.Color3 = objectColor(kind)
    elseif entry.box then
        entry.box:Destroy(); entry.box = nil
    end
end
function removeObjectESP(instance)
    local entry = objectESPRegistry[instance]
    if entry then
        if entry.outline then entry.outline:Destroy() end
        if entry.box then entry.box:Destroy() end
        objectESPRegistry[instance] = nil
    end
end
-- Full scan: only invoked when a toggle changes (initial population / settings change), never per-frame.
function refreshObjectESP()
    if not objectESPAnyEnabled() then objectESPClearAll() return end
    local seen = {}
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if objectKind(instance) then addObjectESP(instance); seen[instance] = true end
    end
    for inst in pairs(objectESPRegistry) do
        if not seen[inst] then removeObjectESP(inst) end
    end
end

-- Gun-drop registry so findDroppedGun never has to scan the whole workspace.
local trackedGuns = {}
function isGunName(name)
    local n = string.lower(name)
    return n == "gundrop" or n == "gun" or string.find(n, "droppedgun", 1, true) or string.find(n, "gun_drop", 1, true)
end
function trackGun(instance)
    if instance:IsA("BasePart") or instance:IsA("Tool") or instance:IsA("Model") then trackedGuns[instance] = true end
end
local function gunPickupPart(container)
    local fallback
    local function inspect(part)
        if not fallback then fallback = part end
        -- GunDrop models often have several mesh parts; only one carries the
        -- TouchInterest/TouchTransmitter that the game's pickup code listens to.
        if part:FindFirstChild("TouchInterest") or part:FindFirstChild("TouchTransmitter")
            or part:FindFirstChildOfClass("TouchTransmitter") then
            return part
        end
    end
    if container:IsA("BasePart") then return inspect(container) or fallback end
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("BasePart") then
            local pickup = inspect(child)
            if pickup then return pickup end
        end
    end
    return fallback
end
function findTrackedGun()
    for inst in pairs(trackedGuns) do
        if inst.Parent then
            local ownerModel = inst:FindFirstAncestorOfClass("Model")
            if not Players:GetPlayerFromCharacter(ownerModel) then
                local part = gunPickupPart(inst)
                if part then return part end
            end
        else
            trackedGuns[inst] = nil
        end
    end
end

Workspace.DescendantAdded:Connect(function(instance)
    if isGunName(instance.Name) then trackGun(instance) end
    if objectESPAnyEnabled() then addObjectESP(instance) end
end)
Workspace.DescendantRemoving:Connect(function(instance)
    trackedGuns[instance] = nil
    removeObjectESP(instance)
end)

-- Seed the gun registry once at startup so already-present drops are tracked.
for _, inst in ipairs(Workspace:GetDescendants()) do
    if isGunName(inst.Name) then trackGun(inst) end
end

--=================================================== TARGET SELECTION
function getAimPart(player)
    local char = player and player.Character
    if not char then return nil end
    local partName = config.hitPart
    if partName == "Random" then
        local opts = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
        partName = opts[math.random(#opts)]
    end
    local part = char:FindFirstChild(partName)
    if not part then part = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart end
    return part
end
function inFOV(player)
    if config.fovSize <= 0 then return true end
    local cam = Workspace.CurrentCamera
    local part = getAimPart(player)
    if not cam or not part then return false end
    local screen = cam:WorldToViewportPoint(part.Position)
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    return (Vector2.new(screen.X, screen.Y) - center).Magnitude <= config.fovSize / 2
end
function passesFilters(player)
    if player == nil or player == LocalPlayer then return false end
    if not validTarget(player) then return false end
    if playerIsInLobby(player) then return false end
    if isFriend(player) then return false end
    if config.maxDistance > 0 and distanceTo(player) > config.maxDistance then return false end
    return true
end
function selectTarget(mode)
    mode = mode or config.targetMode
    if mode == "Murderer" then return passesFilters(murderer) and murderer or nil end
    if mode == "Sheriff" then return passesFilters(sheriff) and sheriff or nil end
    if mode == "Hero" then return passesFilters(hero) and hero or nil end
    if mode == "Selected" then
        local p = config.selectedPlayer and Players:FindFirstChild(config.selectedPlayer)
        return passesFilters(p) and p or nil
    end
    if mode == "Nearest" then
        local best, bd
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then local d = distanceTo(p); if not bd or d < bd then best, bd = p, d end end
        end
        return best
    end
    if mode == "Crosshair" then
        local cam = Workspace.CurrentCamera
        local best, bd
        if cam then
            local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            for _, p in ipairs(getPlayers()) do
                if passesFilters(p) then
                    local part = getAimPart(p)
                    if part then
                        local screen = cam:WorldToViewportPoint(part.Position)
                        if screen.Z > 0 then
                            local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                            if not bd or d < bd then best, bd = p, d end
                        end
                    end
                end
            end
        end
        return best
    end
    if mode == "Lowest Health" then
        local best, bh
        for _, p in ipairs(getPlayers()) do
            if passesFilters(p) then
                local hum = p.Character and p.Character:FindFirstChildWhichIsA("Humanoid")
                local h = hum and hum.Health or math.huge
                if not bh or h < bh then best, bh = p, h end
            end
        end
        return best
    end
    if mode == "Random" then
        local list = {}
        for _, p in ipairs(getPlayers()) do if passesFilters(p) then list[#list + 1] = p end end
        if #list > 0 then return list[math.random(#list)] end
        return nil
    end
    return passesFilters(murderer) and murderer or nil
end
function targetPart()
    local player = selectTarget()
    if not player then player = findByKnife() end
    local character = player and player.Character
    if not character then return nil end
    return getAimPart(player) or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end
function findNearestKnifeTarget()
    local root = localRoot()
    if not root then return nil end
    local closest, closestDistance
    for _, player in ipairs(getPlayers()) do
        if passesFilters(player) then
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local d = (targetRoot.Position - root.Position).Magnitude
                if not closestDistance or d < closestDistance then closest, closestDistance = player, d end
            end
        end
    end
    return closest
end
function knifeTargetPlayer()
    if config.knifePrioritizeSheriff then
        local sheriffPlayer = findSheriff()
        if passesFilters(sheriffPlayer) then return sheriffPlayer end
    end
    return findNearestKnifeTarget()
end
function knifeTargetPart()
    local player = knifeTargetPlayer()
    local character = player and player.Character
    if not character then return nil end
    return getAimPart(player) or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

--================================================= PREDICTION ENGINE
local PingProfiles = {
    { Ping = 20, Sim = 48, Interval = 70, H = 154, V = 144, X = -5, Y = -14, Z = 0 },
    { Ping = 50, Sim = 54, Interval = 66, H = 162, V = 152, X = -6, Y = -14, Z = 0 },
    { Ping = 100, Sim = 68, Interval = 60, H = 176, V = 166, X = -8, Y = -15, Z = 0 },
    { Ping = 150, Sim = 72, Interval = 64, H = 182, V = 170, X = -9, Y = -12, Z = 0 },
    { Ping = 200, Sim = 76, Interval = 70, H = 188, V = 174, X = -10, Y = -11, Z = 0 },
    { Ping = 300, Sim = 82, Interval = 76, H = 196, V = 180, X = -12, Y = -10, Z = 0 },
}
function interpolateProfile(ping)
    local a, b = PingProfiles[1], PingProfiles[1]
    if ping >= PingProfiles[#PingProfiles].Ping then
        a, b = PingProfiles[#PingProfiles], PingProfiles[#PingProfiles]
    else
        for index = 1, #PingProfiles - 1 do
            if ping >= PingProfiles[index].Ping and ping <= PingProfiles[index + 1].Ping then a, b = PingProfiles[index], PingProfiles[index + 1]; break end
        end
    end
    local span = b.Ping - a.Ping
    local alpha = span > 0 and math.clamp((ping - a.Ping) / span, 0, 1) or 0
    alpha = alpha * alpha * (3 - 2 * alpha)
    local function mix(key) return a[key] + (b[key] - a[key]) * alpha end
    return { Sim = math.floor(mix("Sim") + 0.5), Interval = math.floor(mix("Interval") + 0.5),
        H = math.floor(mix("H") + 0.5), V = math.floor(mix("V") + 0.5),
        X = math.floor(mix("X") + 0.5), Y = math.floor(mix("Y") + 0.5), Z = math.floor(mix("Z") + 0.5) }
end
function autoTuneForPing()
    if not config.prioritizePing then return end
    local now = os.clock()
    if now - lastAutoTune < 0.4 then return end
    lastAutoTune = now
    local pingMs = math.clamp(math.floor(cachedPing * 1000 + 0.5), 5, 350)
    if config.manualPingMs ~= pingMs then
        config.manualPingMs = pingMs
        local control = revertControls.manualPingMs
        if type(control) == "table" and type(control.SetValue) == "function" then pcall(control.SetValue, control, pingMs)
        elseif type(control) == "function" then pcall(control, pingMs) end
    end
end
function leadTime()
    local prediction
    if config.adaptive then
        local ping = config.prioritizePing and cachedPing or (config.manualPingMs / 1000)
        prediction = ping + config.extraLead
        if config.predictLag then
            local samplingDelay = math.clamp(config.predictionIntervalMs / 2000, 0, 0.05)
            prediction = prediction + samplingDelay + math.max(0, ping - 0.10) * 0.15
        end
    else
        prediction = config.fixedLead
    end
    return math.clamp(prediction, 0.02, math.min(config.maxLead, config.maxSimulationMs / 1000))
end
function sampleMotion(part)
    local now = os.clock()
    if motionPart ~= part then
        motionPart = part; motionSamples = {}; measuredVelocity = part.AssemblyLinearVelocity
        previousEstimatedVelocity = measuredVelocity; estimatedAcceleration = Vector3.zero
    end
    local last = motionSamples[#motionSamples]
    if not last or now - last.time >= math.max(0.016, config.predictionIntervalMs / 1000) then
        motionSamples[#motionSamples + 1] = { position = part.Position, time = now }
        while #motionSamples > 8 or (#motionSamples > 2 and now - motionSamples[1].time > 0.35) do table.remove(motionSamples, 1) end
        if #motionSamples >= 2 then
            local first = motionSamples[1]
            local newest = motionSamples[#motionSamples]
            local delta = newest.time - first.time
            if delta > 0.015 then
                local sampled = (newest.position - first.position) / delta
                if sampled.Magnitude < 150 then
                    local oldVelocity = measuredVelocity
                    measuredVelocity = measuredVelocity:Lerp(sampled, 0.55)
                    local sampleDelta = last and math.max(now - last.time, 0.016) or delta
                    local acceleration = (measuredVelocity - oldVelocity) / sampleDelta
                    if acceleration.Magnitude < 120 then estimatedAcceleration = estimatedAcceleration:Lerp(acceleration, 0.25)
                    else estimatedAcceleration = Vector3.zero end
                    previousEstimatedVelocity = oldVelocity
                end
            end
        end
    end
    motionPosition = part.Position; motionTime = now
end
function calculateAim(part)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    local acceleration = Vector3.zero
    if config.predictLag and motionPart == part and #motionSamples >= 2 then
        local disagreement = (assembly - measuredVelocity).Magnitude
        local measuredWeight = math.clamp(0.75 - disagreement / 120, 0.35, 0.75)
        velocity = assembly:Lerp(measuredVelocity, measuredWeight)
        acceleration = estimatedAcceleration
    end
    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local yVelocity = config.predictJump and velocity.Y * vertical or 0
    local predictedVelocity = Vector3.new(velocity.X * horizontal, yVelocity, velocity.Z * horizontal)
    local time = leadTime()
    local displacement = predictedVelocity * time
    if config.predictLag then
        local horizontalAcceleration = Vector3.new(acceleration.X, 0, acceleration.Z)
        displacement = displacement + horizontalAcceleration * (0.5 * time * time)
    end
    if config.predictJump then
        local humanoid = part.Parent and part.Parent:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            displacement = displacement + Vector3.new(0, -0.5 * Workspace.Gravity * time * time, 0)
        end
    end
    if displacement.Magnitude > 18 then displacement = displacement.Unit * 18 end
    local offset = Vector3.new(part.Size.X * config.offsetX / 100, part.Size.Y * config.offsetY / 100, part.Size.Z * config.offsetZ / 100)
    return part.Position + displacement + offset
end
function calculateKnifeAim(part, origin)
    sampleMotion(part)
    local assembly = part.AssemblyLinearVelocity
    local velocity = assembly
    if config.predictLag and motionPart == part and #motionSamples >= 2 then velocity = assembly:Lerp(measuredVelocity, 0.65) end
    local horizontal = config.horizontalMultiplier / 100
    local vertical = config.verticalMultiplier / 100
    local predictedVelocity = Vector3.new(velocity.X * horizontal, config.predictJump and velocity.Y * vertical or 0, velocity.Z * horizontal)
    local distance = (part.Position - origin).Magnitude
    local travelTime = math.clamp(distance / 125, 0, 0.55)
    local time = math.clamp(leadTime() + travelTime, 0.03, 0.7)
    local offset = Vector3.new(part.Size.X * config.offsetX / 100, part.Size.Y * config.offsetY / 100, part.Size.Z * config.offsetZ / 100)
    return part.Position + predictedVelocity * time + offset
end
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true
function targetVisible(part, forceWallCheck)
    if not (forceWallCheck or config.wallCheck) then return true end
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    if not originPart or not part then return false end
    wallCheckParams.FilterDescendantsInstances = { character }
    local result = Workspace:Raycast(originPart.Position, part.Position - originPart.Position, wallCheckParams)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

--=================================================== REMOTE MATCHERS
function knifeRemote(remote, args)
    -- MM2's working throw path sends two CFrames through KnifeThrown.
    if not config.knifeEnabled or args.n < 2 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    if remote.Name ~= "KnifeThrown" then return false end
    if typeof(args[1]) ~= "CFrame" or typeof(args[2]) ~= "CFrame" then return false end
    local character = LocalPlayer.Character
    local knife = character and character:FindFirstChild("Knife")
    if knife and remote:IsDescendantOf(knife) then return true end
    if character and remote:IsDescendantOf(character) then return true end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameplay = remotes and remotes:FindFirstChild("Gameplay")
    return gameplay ~= nil and remote:IsDescendantOf(gameplay)
end
local function localGunTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun"))
end
local function remoteBelongsToLocalGun(remote)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local characterGun = character and character:FindFirstChild("Gun")
    local backpackGun = backpack and backpack:FindFirstChild("Gun")
    return (characterGun and remote:IsDescendantOf(characterGun))
        or (backpackGun and remote:IsDescendantOf(backpackGun))
end
function shotRemote(remote, args)
    if not config.enabled or args.n < 1 then return false end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return false end
    -- Exact current path: Players.LocalPlayer.Backpack/Character.Gun.Shoot.
    -- Check both copies because the tool can move between Backpack and Character
    -- during equip/unequip while the hook remains installed.
    return remote.Name == "Shoot" and remoteBelongsToLocalGun(remote)
end
local function fallbackGunOrigin()
    local gun = localGunTool()
    local handle = gun and gun:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then return handle.Position end
    local character = LocalPlayer.Character
    local root = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
    return root and root.Position or nil
end
local function vectorOrCFramePosition(value)
    if typeof(value) == "CFrame" then return value.Position end
    if typeof(value) == "Vector3" then return value end
    return nil
end
local function hasCFrameArgument(args)
    for index = 1, args.n do
        if typeof(args[index]) == "CFrame" then return true end
    end
    return false
end
function redirect(remote, args)
    local part, useWallCheck, isKnife = nil, false, false
    if shotRemote(remote, args) then
        if config.aimKey ~= "None" and not aimHeld then return end
        -- CFrame mode intentionally only rewrites the CFrame protocol. Remote
        -- mode supports both the current Vector3 protocol and old CFrame pairs.
        if config.shotMethod == "CFrame" and not hasCFrameArgument(args) then return end
        part = targetPart(); useWallCheck = config.wallCheck
    elseif knifeRemote(remote, args) then
        part = knifeTargetPart(); useWallCheck = config.knifeWallCheck; isKnife = true
    else
        return
    end
    if not part then return end
    if useWallCheck and not targetVisible(part, true) then return end

    -- The supplied Shoot remote is a Vector3 protocol in the current client,
    -- while older Gun tools used two CFrames. Find the origin/aim pair without
    -- disturbing Handle/target metadata arguments.
    local numericIndices = {}
    for index = 1, args.n do
        if vectorOrCFramePosition(args[index]) then numericIndices[#numericIndices + 1] = index end
    end
    if #numericIndices == 0 then return end
    local originIndex = numericIndices[1]
    local aimIndex = numericIndices[2]
    local firstValue = args[originIndex]
    local secondValue = aimIndex and args[aimIndex]
    local fallbackOrigin = fallbackGunOrigin()
    -- Also accept the alternate Vector3 order: direction, origin.
    if aimIndex and typeof(firstValue) == "Vector3" and typeof(secondValue) == "Vector3" then
        if firstValue.Magnitude <= 1.5 and secondValue.Magnitude > 1.5 then
            originIndex, aimIndex = numericIndices[2], numericIndices[1]
        elseif fallbackOrigin then
            local firstDistance = (firstValue - fallbackOrigin).Magnitude
            local secondDistance = (secondValue - fallbackOrigin).Magnitude
            if secondDistance + 0.5 < firstDistance then
                originIndex, aimIndex = numericIndices[2], numericIndices[1]
            end
        end
    end
    local origin = vectorOrCFramePosition(args[originIndex])
    if not aimIndex then
        aimIndex = originIndex
        origin = fallbackOrigin or origin
    end
    if not origin then return end

    local aim = isKnife and calculateKnifeAim(part, origin) or calculateAim(part)
    local originalAim = args[aimIndex]
    if typeof(originalAim) == "CFrame" then
        args[aimIndex] = CFrame.new(aim)
    elseif typeof(originalAim) == "Vector3" then
        -- A few builds send a unit direction instead of a world-space hit
        -- point. Preserve that protocol when the original vector is tiny.
        if originalAim.Magnitude <= 1.5 and (aim - origin).Magnitude > 0.01 then
            args[aimIndex] = (aim - origin).Unit
        else
            args[aimIndex] = aim
        end
    end
    if config.alignDirection and typeof(args[originIndex]) == "CFrame" and (aim - origin).Magnitude > 0.01 then
        args[originIndex] = CFrame.lookAt(origin, aim)
    end
    redirected = redirected + 1
end

--======================================================== HOOK SETUP
function installHook()
    if hooked then return true end
    local wrap = type(newcclosure) == "function" and newcclosure or function(callback) return callback end

    -- Prefer __namecall: this catches the exact Gun.Shoot:FireServer(...) call
    -- even when the executor does not expose the RemoteEvent's C closure.
    if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
        local originalNamecall
        local ok, err = pcall(function()
            originalNamecall = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                local args = table.pack(...)
                if getnamecallmethod() == "FireServer" then
                    pcall(redirect, self, args)
                end
                return originalNamecall(self, table.unpack(args, 1, args.n))
            end))
        end)
        if ok and type(originalNamecall) == "function" then
            hooked = true
            return true
        end
    end

    -- Compatibility fallback for executors that only provide hookfunction.
    if type(hookfunction) ~= "function" then notify("Remote hook is unavailable", 6); return false end
    local probe = Instance.new("RemoteEvent")
    local original
    local ok, err = pcall(function()
        original = hookfunction(probe.FireServer, wrap(function(self, ...)
            local args = table.pack(...)
            pcall(redirect, self, args)
            return original(self, table.unpack(args, 1, args.n))
        end))
    end)
    probe:Destroy()
    if not ok then notify("Hook failed: " .. tostring(err), 6); return false end
    hooked = true
    return true
end
function toggle(value)
    config.enabled = value == true
    if config.enabled then
        if not installHook() then config.enabled = false return end
        task.spawn(refreshTarget)
        notify("Enabled", 2)
    else
        notify("Disabled", 2)
    end
end

--======================================================= FIRE GUN
function findGunRemote()
    local gun = localGunTool()
    if not gun then return nil end
    local shoot = gun:FindFirstChild("Shoot", true)
    if shoot and shoot:IsA("RemoteEvent") then return shoot end
    for _, object in ipairs(gun:GetDescendants()) do
        if object:IsA("RemoteEvent") then return object end
    end
end
function fireGunAt(player)
    if shootBusy then return false end
    shootBusy = true
    local success = false
    pcall(function()
        if not validTarget(player) then return end
        local part = getAimPart(player)
        local camera = Workspace.CurrentCamera
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not part or not camera or not character or not humanoid then return end
        if config.wallCheck and not targetVisible(part) then return end
        local autoEquipped = false
        local gun = character:FindFirstChild("Gun")
        if not gun and backpack then
            gun = backpack:FindFirstChild("Gun")
            if gun then humanoid:EquipTool(gun); autoEquipped = true; task.wait(0.08) end
        end
        local remote = findGunRemote()
        if not remote then if autoEquipped then humanoid:UnequipTools() end; return end
        if not config.enabled then
            sampleMotion(part)
            task.wait(math.clamp(config.predictionIntervalMs / 1000, 0.025, 0.07))
            sampleMotion(part)
        end
        local aim = calculateAim(part)
        local handle = gun and gun:FindFirstChild("Handle", true)
        local origin = handle and handle.Position or camera.CFrame.Position
        -- Shoot Murder uses the same Gun.Shoot remote as normal firing. Use
        -- the selected protocol so the button and Silent Aim share one path.
        if config.shotMethod == "CFrame" then
            remote:FireServer(CFrame.lookAt(origin, aim), CFrame.new(aim))
        else
            remote:FireServer(origin, aim)
        end
        success = true
        if autoEquipped then task.wait(0.12); if humanoid.Parent then humanoid:UnequipTools() end end
    end)
    shootBusy = false
    return success
end
function shootTarget()
    local player = selectTarget()
    if not player then refreshTarget(); player = selectTarget() end
    if player then return fireGunAt(player) end
    return false
end
task.spawn(function()
    while running do
        if config.autoFire and config.enabled and (config.autoFireKey == "None" or autoFireHeld) then
            local player = selectTarget()
            if player and inFOV(player) then
                local part = getAimPart(player)
                if part and (not config.wallCheck or targetVisible(part)) then fireGunAt(player) end
            end
        end
        task.wait(0.03)
    end
end)

--====================================================== SHOOT BUTTON
function removeShootButton()
    if shootGui then shootGui:Destroy(); shootGui = nil; shootButton = nil end
end
function createShootButton()
    if shootButton then return end
    local parent = CoreGui
    if type(gethui) == "function" then local ok, result = pcall(gethui); if ok and typeof(result) == "Instance" then parent = result end end
    if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui") end
    shootGui = Instance.new("ScreenGui")
    shootGui.Name = "MM2ShootMurdererButton"; shootGui.ResetOnSpawn = false; shootGui.IgnoreGuiInset = true
    shootGui.DisplayOrder = 80; shootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; shootGui.Parent = parent
    local button = Instance.new("TextButton")
    button.Name = "ShootMurderer"
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    -- Start in the right-side safe rail, outside the main window.  The v4
    -- position key is intentionally new so an old centre-screen position is
    -- not restored over the UI after updating.
    button.Position = NoirPersistence.GetPosition("shoot_v2", UDim2.new(1, -132, 1, -124))
    button.Size = UDim2.new(0, 194, 0, 66)
    button.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    button.BackgroundTransparency = 0.28
    button.BorderSizePixel = 0
    button.Text = "Shoot Murder"
    button.TextColor3 = Color3.fromRGB(245, 245, 248)
    button.TextSize = 17
    button.TextWrapped = true
    button.Font = Enum.Font.Gotham
    button.ClipsDescendants = false
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = shootGui
    shootButton = button
    local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0, 16); corner2.Parent = button
    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = Color3.fromRGB(255, 255, 255); stroke2.Thickness = 2; stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke2.Parent = button
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    gradient.Parent = stroke2
    table.insert(gradientStrokes, gradient)
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(105, 105, 112); innerStroke.Transparency = 0.5; innerStroke.Thickness = 1
    innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; innerStroke.Parent = button
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = innerStroke
    table.insert(gradientStrokes, innerGradient)
    local traceA = Instance.new("Frame"); traceA.AnchorPoint = Vector2.new(.5, .5); traceA.Position = UDim2.fromScale(0, .08)
    traceA.Size = UDim2.fromOffset(8, 8); traceA.BackgroundColor3 = Color3.new(1, 1, 1); traceA.BorderSizePixel = 0; traceA.ZIndex = 10; traceA.Parent = button
    local traceB = traceA:Clone(); traceB.Position = UDim2.fromScale(1, .92); traceB.Parent = button
    Instance.new("UICorner", traceA).CornerRadius = UDim.new(1, 0)
    Instance.new("UICorner", traceB).CornerRadius = UDim.new(1, 0)
    traceA.Visible = false; traceB.Visible = false
    local sound = Instance.new("Sound"); sound.Name = "Sound"; sound.SoundId = "rbxassetid://3868133279"; sound.Volume = 0.5; sound.Parent = button
    local normalSize = UDim2.new(0, 194, 0, 66)
    local pressedSize = UDim2.new(0, 206, 0, 72)
    local pressTween = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local dragging, moved, dragStart, startPosition, dragInput = false, false, nil, nil, nil
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = not config.lockShootButton; moved = false; dragStart = input.Position; startPosition = button.Position
            TweenService:Create(button, pressTween, { Size = pressedSize, TextSize = 18, BackgroundColor3 = Color3.fromRGB(27,27,31) }):Play()
            button.Text = "T A R G E T   L O C K"
            traceA.Visible = true; traceB.Visible = true
            traceA.Position = UDim2.fromScale(0, .08); traceB.Position = UDim2.fromScale(1, .92)
            TweenService:Create(traceA, TweenInfo.new(.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(1, .08) }):Play()
            TweenService:Create(traceB, TweenInfo.new(.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0, .92) }):Play()
            sound:Play()
        end
    end)
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput and not config.lockShootButton then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then moved = true end
            -- Deliberately do not clamp the button: it can be moved freely,
            -- including partly outside the screen, as requested.
            button.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            NoirPersistence.SetPosition("shoot_v2", button.Position)
            TweenService:Create(button, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = normalSize, TextSize = 17, BackgroundColor3 = Color3.fromRGB(8,8,10), BackgroundTransparency = .28 }):Play()
            button.Text = "Shoot Murder"
            traceA.Visible = false; traceB.Visible = false
        end
    end)
    button.Activated:Connect(function() if not moved then task.spawn(shootTarget) end end)
end
function setShootButtonVisible(value)
    config.showShootButton = value == true
    if config.showShootButton then createShootButton() else removeShootButton() end
end

--======================================================== FOV CIRCLE
local fovCircle = New("Frame", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
    BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 200), Visible = false, ZIndex = 2 })
New("UICorner", { Parent = fovCircle, CornerRadius = UDim.new(.5, 0) })
local fovStroke = New("UIStroke", { Parent = fovCircle, Color = Color3.fromRGB(232,232,236), Thickness = 1.5, Transparency = .35 })
function updateFovCircle()
    -- FOV controls were removed from Silent Aim; keep the legacy object hidden
    -- even when an old preset contains showFov/fovSize values.
    fovCircle.Visible = false
end

--======================================================= ROUND TIMER
local roundTimerGui
-- MM2 has shipped several HUD variants: some use 1:23, some use 83s,
-- and some put a plain number inside a TextLabel named Timer.  Normalize all
-- of them here instead of relying on one exact GUI hierarchy or format.
local function parseTimerText(value, nameHint)
    local raw = tostring(value or ""):gsub("<.->", "")
    raw = raw:gsub("[%c]+", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then return nil end
    local name = string.lower(tostring(nameHint or ""))
    local namedTimer = string.find(name, "timer", 1, true)
        or string.find(name, "clock", 1, true)
        or string.find(name, "countdown", 1, true)
        or string.find(name, "round", 1, true)
        or string.find(name, "timeleft", 1, true)
        or string.find(name, "time", 1, true)
    local minutes, seconds = raw:match("^(%d+)%s*[:%.]%s*(%d%d)$")
    if not minutes then minutes, seconds = raw:match("(%d+)%s*[:%.]%s*(%d%d)") end
    if minutes and seconds then
        local total = tonumber(minutes) * 60 + tonumber(seconds)
        return string.format("%dm %02ds", math.floor(total / 60), total % 60), total, 125
    end
    minutes, seconds = raw:match("^(%d+)%s*[mM]%s*[, ]*%s*(%d+)%s*[sS]$")
    if minutes and seconds then
        local total = tonumber(minutes) * 60 + tonumber(seconds)
        return string.format("%dm %02ds", math.floor(total / 60), total % 60), total, 120
    end
    seconds = raw:match("^(%d+)%s*[sS]$")
    if seconds then
        local total = tonumber(seconds)
        return string.format("%dm %02ds", math.floor(total / 60), total % 60), total, 115
    end
    if namedTimer then
        seconds = raw:match("^(%d+)$")
        if seconds and tonumber(seconds) <= 600 then
            local total = tonumber(seconds)
            return string.format("%dm %02ds", math.floor(total / 60), total % 60), total, 105
        end
    end
    return nil
end
-- Decode every shape observed from the supplied Extras.GetTimer RemoteFunction.
-- Some builds return a number, others a formatted string or a small table.
local function decodeTimerResult(value)
    if typeof(value) == "number" then
        local seconds = math.max(0, math.floor(value + .5))
        return seconds > 0 and string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60) or nil, seconds, nil
    end
    if typeof(value) == "string" then
        local text, seconds, score = parseTimerText(value, "GetTimer")
        if text then return text, seconds, nil end
        local phase = string.lower(value)
        if phase == "waiting" or phase == "lobby" or phase == "ended" or phase == "gameover" or phase == "victory" then
            return nil, 0, phase
        end
        return nil
    end
    if typeof(value) == "table" then
        local phase = value.Phase or value.phase or value.State or value.state or value.Status or value.status
        local phaseName = string.lower(tostring(phase or ""))
        if phaseName == "waiting" or phaseName == "lobby" or phaseName == "ended" or phaseName == "gameover" or phaseName == "victory" then
            return nil, 0, phaseName
        end
        local keys = { "Time", "time", "Timer", "timer", "TimeLeft", "timeLeft", "Remaining", "remaining", "Seconds", "seconds", "Value", "value" }
        for _, key in ipairs(keys) do
            local text, seconds = decodeTimerResult(value[key])
            if text or seconds then return text, seconds, phaseName end
        end
        for _, item in pairs(value) do
            local text, seconds = decodeTimerResult(item)
            if text or seconds then return text, seconds, phaseName end
        end
    end
    return nil
end
local function resetRoundTimer()
    roundResetToken += 1
    roundState = "waiting"
    lastRoundResetAt = os.clock()
    roundTimerEndsAt = nil
    roundPendingStart = nil
    if roundTimerGui and roundTimerGui.Parent then roundTimerGui.Text = "WAITING" end
end
local function beginRoundTimer(roundLength)
    roundResetToken += 1
    roundState = "playing"
    roundPendingStart = nil
    roundLength = math.clamp(tonumber(roundLength) or 180, 1, 600)
    roundTimerEndsAt = os.clock() + roundLength
end
function setRoundTimerVisible(value)
    if not value then
        if roundTimerGui then roundTimerGui:Destroy(); roundTimerGui = nil end
        return
    end
    if roundTimerGui then return end
    roundTimerGui = Instance.new("TextLabel")
    roundTimerGui.Name = "NoirRoundTimer"
    roundTimerGui.Parent = gui
    roundTimerGui.AnchorPoint = Vector2.new(.5, 0)
    roundTimerGui.Position = UDim2.new(.5, 0, 0, 18)
    roundTimerGui.Size = UDim2.fromOffset(220, 50)
    roundTimerGui.BackgroundColor3 = C.panel
    roundTimerGui.BackgroundTransparency = .12
    roundTimerGui.TextColor3 = C.text
    roundTimerGui.Text = (roundState == "waiting" or roundState == "unknown") and "WAITING" or "STARTING"
    roundTimerGui.TextSize = 20
    roundTimerGui.Font = Enum.Font.GothamBold
    roundTimerGui.ZIndex = 900
    corner(roundTimerGui, 15); stroke(roundTimerGui, C.border, .15)
    local thisGui = roundTimerGui
    task.spawn(function()
        local getTimer
        while roundTimerGui == thisGui and thisGui.Parent do
            local found, bestScore, phase, discoveredSeconds
            local activeRound = roundState ~= "waiting" or (os.clock() - lastRoundResetAt > 1)

            -- Do not read stale GetTimer/UI values while the round is over.
            -- The old implementation did exactly that, so the previous round's
            -- number immediately reappeared after GameOver/VictoryScreen.
            if activeRound then
                if not (getTimer and getTimer.Parent) then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local extras = remotes and remotes:FindFirstChild("Extras")
                    getTimer = (extras and extras:FindFirstChild("GetTimer")) or ReplicatedStorage:FindFirstChild("GetTimer", true)
                end
                if getTimer and getTimer:IsA("RemoteFunction") then
                    local ok, res = pcall(function() return getTimer:InvokeServer() end)
                    if ok and res ~= nil then
                        local timerText, timerSeconds, timerPhase = decodeTimerResult(res)
                        phase = timerPhase ~= "" and timerPhase or phase
                        if timerPhase == "waiting" or timerPhase == "lobby" or timerPhase == "ended" or timerPhase == "gameover" or timerPhase == "victory" then
                            resetRoundTimer()
                        elseif timerText and timerSeconds and timerSeconds > 0 then
                            found, bestScore, discoveredSeconds = timerText, 200, timerSeconds
                        elseif timerSeconds == 0 and (roundState == "starting" or roundState == "playing") then
                            resetRoundTimer()
                        end
                    end
                end

                -- Fallback: scan PlayerGui during an active/starting round.
                -- activeRound also remains true a moment after a reset, so this
                -- can discover the next round even when RoundStart is absent or
                -- the remote is created after this script starts.
                if found and roundState == "playing" then
                    -- An authoritative remote value already won; do not replace
                    -- it with a decorative label from PlayerGui.
                else
                    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if pg and activeRound then
                        for _, v in ipairs(pg:GetDescendants()) do
                            if (v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox")) and v ~= thisGui then
                                local lowerName = string.lower(v.Name)
                                local parentName = v.Parent and string.lower(v.Parent.Name) or ""
                                local hint = lowerName .. " " .. parentName
                                local timerText, timerSeconds, score = parseTimerText(v.Text, hint)
                                if timerText and timerSeconds and timerSeconds > 0 and (not bestScore or score > bestScore) then
                                    found, bestScore, discoveredSeconds = timerText, score, timerSeconds
                                end
                            end
                        end
                    end
                    if found and (roundState == "unknown" or roundState == "waiting") then
                        if discoveredSeconds and discoveredSeconds <= 15 then
                            roundState = "starting"
                            roundPendingStart = roundPendingStart or (os.clock() + discoveredSeconds)
                        else
                            roundState = "playing"
                            if discoveredSeconds and not roundTimerEndsAt then
                                roundTimerEndsAt = os.clock() + discoveredSeconds
                            end
                        end
                    end
                end
            end

            if roundState == "starting" and roundPendingStart then
                local pre = math.ceil(roundPendingStart - os.clock())
                if pre > 0 then
                    found = "Starts in " .. tostring(pre)
                else
                    roundPendingStart = nil
                    beginRoundTimer()
                    found = "3m 00s"
                end
            elseif roundState == "playing" and roundTimerEndsAt then
                local left = math.max(0, math.floor(roundTimerEndsAt - os.clock() + .5))
                if left > 0 then
                    if not found then found = string.format("%dm %02ds", math.floor(left / 60), left % 60) end
                else
                    resetRoundTimer()
                    found = "WAITING"
                end
            end

            if roundState == "waiting" then
                thisGui.Text = "WAITING"
            elseif roundState == "starting" then
                thisGui.Text = found or "STARTING"
            else
                thisGui.Text = phase and (string.upper(tostring(phase)) .. "  " .. (found or "")) or (found or "WAITING")
            end
            task.wait(.2)
        end
    end)
end

--======================================================== MISC / UTILITY
local utility = {
    walkEnabled = false, walkSpeed = 16, jumpEnabled = false, jumpPower = 50,
    autoGrab = false, grabSafety = true, gunAura = false, gunAuraRange = 10,
    notifyDropped = false, notifyPickup = false,
    touchFling = false, touchPower = 100,
    antiFling = false, flingAll = false,
    autoFlingSheriff = false, autoFlingMurderer = false,
    flingDuration = 2, flingPower = 1,
    antiAfk = false, selectedPlayer = nil, roundTimer = false,
    chatSpam = false, chatMessage = "", chatDelay = 3,
}

function applyCharacterMods()
    local humanoid = localHumanoid()
    if not humanoid then return end
    if utility.walkEnabled then humanoid.WalkSpeed = utility.walkSpeed end
    if utility.jumpEnabled then humanoid.UseJumpPower = true; humanoid.JumpPower = utility.jumpPower end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); applyCharacterMods() end)
applyCharacterMods()

function findSheriff()
    if validTarget(sheriff) then return sheriff end
    return findByGun()
end

function playerNameList()
    local list = { "None" }
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer then list[#list + 1] = player.Name end
    end
    table.sort(list, function(a, b) return a == "None" or (b ~= "None" and string.lower(a) < string.lower(b)) end)
    return list
end

local lastGunDeepScan = 0
local pickupRemoteCache
function findPickupRemote()
    if pickupRemoteCache and pickupRemoteCache.Parent then return pickupRemoteCache end
    pickupRemoteCache = nil
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local n = string.lower(remote.Name)
            if (string.find(n, "gun", 1, true) and (string.find(n, "pickup", 1, true) or string.find(n, "grab", 1, true) or string.find(n, "get", 1, true))) or n == "pickupgun" then
                pickupRemoteCache = remote
                break
            end
        end
    end
    return pickupRemoteCache
end
function findDroppedGun()
    -- 1) fast registry lookup (kept up to date by DescendantAdded/Removing)
    local tracked = findTrackedGun()
    if tracked then return tracked end
    -- 2) throttled fallback (at most once per second) instead of a full scan every tick
    local now = os.clock()
    if now - lastGunDeepScan < 1 then return nil end
    lastGunDeepScan = now
    local direct = Workspace:FindFirstChild("GunDrop", true)
    if direct then
        local part = gunPickupPart(direct)
        if part then return part end
    end
end

local function localHasGun()
    return playerHasTool(LocalPlayer, "Gun") ~= nil
end
local function localIsMurderer()
    return murderer == LocalPlayer
        or roleCache[LocalPlayer.UserId] == "murderer"
        or playerHasTool(LocalPlayer, "Knife") ~= nil
end
local function gunRoundActive()
    local humanoid = localHumanoid()
    if not humanoid or humanoid.Health <= 0 then return false end
    -- A round must be positively identified by RoundStart/role data.  This
    -- also keeps a persisted Auto Grab toggle idle while the player is in the
    -- lobby after dying.
    if roundState ~= "starting" and roundState ~= "playing" then return false end
    return true
end

function grabGun(silent)
    if not gunRoundActive() then
        if not silent then notify("Gun pickup is unavailable in the lobby", 2.5) end
        return false
    end
    if localHasGun() then return true end
    if utility.grabSafety and localIsMurderer() then
        if not silent then notify("Pickup blocked by Safety Check", 2.5) end
        return false
    end
    local gun = findDroppedGun()
    if not gun then
        if not silent then notify("Dropped gun not found", 2) end
        return false
    end
    local root = localRoot()
    if not root then return false end
    local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart", true)
    if not part or not part.Parent then return false end

    local attempted = false
    -- MM2's normal dropped-gun pickup is a touch interaction.  Verify the
    -- local inventory after the attempt instead of treating the existence of
    -- firetouchinterest as a successful pickup.
    if type(firetouchinterest) == "function" then
        local ok = pcall(function()
            firetouchinterest(root, part, 0)
            task.wait(.05)
            firetouchinterest(root, part, 1)
        end)
        attempted = ok or attempted
    end
    -- Keep the legacy fallback for executors that do not expose touch events.
    pcall(function() part.CFrame = root.CFrame end)

    local pickupRemote = findPickupRemote()
    if pickupRemote then
        local ok = pcall(function()
            if pickupRemote:IsA("RemoteFunction") then
                pickupRemote:InvokeServer(part)
            else
                pickupRemote:FireServer(part)
            end
        end)
        attempted = ok or attempted
    end

    local pickedUp = localHasGun()
    if not pickedUp and not silent and not attempted then notify("Gun pickup failed", 3) end
    return pickedUp or attempted
end

function fpsBoost()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
            object.Enabled = false
        elseif object:IsA("Decal") or object:IsA("Texture") then
            object.Transparency = 1
        end
    end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
end

function lessLag()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then object.Material = Enum.Material.SmoothPlastic; object.Reflectance = 0 end
    end
end

function removeBarriers()
    for _, object in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(object.Name)
        if object:IsA("BasePart") and (string.find(name, "barrier", 1, true) or string.find(name, "invisiblewall", 1, true)) then
            object.CanCollide = false; object.Transparency = 1
        end
    end
end

function nearestPlayer(maxDistance)
    local root = localRoot(); if not root then return nil end
    local best, bestDistance
    for _, player in ipairs(getPlayers()) do
        if player ~= LocalPlayer and validTarget(player) then
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local d = (targetRoot.Position - root.Position).Magnitude
                if (not maxDistance or d <= maxDistance) and (not bestDistance or d < bestDistance) then best, bestDistance = player, d end
            end
        end
    end
    return best
end

-- fling machinery
local flingBusy = false
local flingBodyVelocity, flingOldPosition
local flingDestroyHeight = Workspace.FallenPartsDestroyHeight
function cleanupFling(root, humanoid, character)
    if flingBodyVelocity then pcall(function() flingBodyVelocity:Destroy() end); flingBodyVelocity = nil end
    if root and root.Parent then
        pcall(function() root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end)
    end
    if humanoid then
        pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        pcall(function() Workspace.CurrentCamera.CameraSubject = humanoid end)
    end
    pcall(function() Workspace.FallenPartsDestroyHeight = flingDestroyHeight end)
    if flingOldPosition and root and root.Parent then
        for _ = 1, 12 do
            pcall(function()
                root.CFrame = flingOldPosition * CFrame.new(0, .5, 0)
                if character.PrimaryPart then character:SetPrimaryPartCFrame(root.CFrame) end
            end)
            pcall(function() root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end)
            if (root.Position - flingOldPosition.Position).Magnitude < 20 then break end
            RunService.Heartbeat:Wait()
        end
    end
    flingBusy = false
end
function flingPlayer(target)
    if flingBusy or not target or target == LocalPlayer or not validTarget(target) then return false end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = humanoid and humanoid.RootPart or localRoot()
    local targetCharacter = target.Character
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildWhichIsA("Humanoid")
    local targetRoot = targetHumanoid and targetHumanoid.RootPart or (targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart"))
    local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
    local accessory = targetCharacter and targetCharacter:FindFirstChildOfClass("Accessory")
    local handle = accessory and accessory:FindFirstChild("Handle")
    local targetPart = targetRoot or targetHead or handle
    if not character or not humanoid or not root or not targetPart then return false end
    if targetHumanoid and targetHumanoid.Sit then notify(target.Name .. " is sitting", 2); return false end
    flingBusy = true
    flingOldPosition = root.CFrame
    pcall(function() Workspace.CurrentCamera.CameraSubject = targetPart end)
    pcall(function() Workspace.FallenPartsDestroyHeight = 0 / 0 end)
    pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    flingBodyVelocity = Instance.new("BodyVelocity")
    flingBodyVelocity.Velocity = Vector3.zero
    flingBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flingBodyVelocity.Parent = root
    local power = math.clamp(utility.flingPower or 1, 1, 3)
    local multiplier = power == 1 and 1 or power == 2 and 1.5 or 2
    local started = os.clock()
    local duration = math.clamp(utility.flingDuration or 2, 1, 5)
    local angle = 0
    while os.clock() - started < duration and targetPart.Parent and humanoid.Health > 0 do
        angle += 100
        local speed = targetPart.AssemblyLinearVelocity.Magnitude
        local move = targetHumanoid and targetHumanoid.MoveDirection or Vector3.zero
        local offset = move * (speed < 50 and speed / 1.25 or 1)
        local y = ((math.floor((os.clock() - started) * 24) % 2) == 0) and 1.5 or -1.5
        local z = speed >= 50 and (targetHumanoid and targetHumanoid.WalkSpeed or 16) or 0
        local cf = CFrame.new(targetPart.Position) * CFrame.new(offset.X, y, offset.Z + z) * CFrame.Angles(math.rad(angle), 0, 0)
        pcall(function()
            root.CFrame = cf
            if character.PrimaryPart then character:SetPrimaryPartCFrame(cf) end
            root.AssemblyLinearVelocity = Vector3.new(9e7 * multiplier, 9e8 * multiplier, 9e7 * multiplier)
            root.AssemblyAngularVelocity = Vector3.new(9e8 * multiplier, 9e8 * multiplier, 9e8 * multiplier)
        end)
        RunService.Heartbeat:Wait()
    end
    cleanupFling(root, humanoid, character)
    return true
end

function applyAntiFling()
    local root = localRoot()
    if not root then return end
    local speed = root.AssemblyLinearVelocity.Magnitude
    if speed > 150 then
        pcall(function() root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end)
    end
end

-- chat helper (legacy + TextChatService)
function sendChat(message)
    if type(message) ~= "string" or message == "" then return false end
    local sent = false
    local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if legacy then
        local say = legacy:FindFirstChild("SayMessageRequest")
        if say and say:IsA("RemoteEvent") then pcall(function() say:FireServer(message, "All") end); sent = true end
    end
    if not sent then
        pcall(function()
            local textChat = game:GetService("TextChatService")
            local channels = textChat:FindFirstChild("TextChannels")
            local general = channels and channels:FindFirstChild("RBXGeneral")
            if general then general:SendAsync(message); sent = true end
        end)
    end
    return sent
end

function serverHop()
    local ok, err = pcall(function()
        local teleport = game:GetService("TeleportService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local body = game:HttpGet(url)
        local data = HttpService:JSONDecode(body)
        local servers = data and data.data
        if not servers or #servers == 0 then notify("No servers found", 4) return end
        local target
        for _, server in ipairs(servers) do
            if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 0) then target = server; break end
        end
        target = target or servers[1]
        if target then teleport:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer) end
    end)
    if not ok then notify("Server hop failed: " .. tostring(err), 5) end
end

function rejoin()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
end

function showMurdererChance()
    local chance = ReplicatedStorage:FindFirstChild("GetChance", true)
    if chance and chance:IsA("RemoteFunction") then
        local ok, value = pcall(function() return chance:InvokeServer() end)
        notify(ok and ("Murderer chance: " .. tostring(value) .. "%") or "Chance unavailable", 4)
    else
        notify("GetChance remote not found", 4)
    end
end

-- anti-afk
do
    local virtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if not utility.antiAfk then return end
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

-- main utility loop
task.spawn(function()
    local hadDrop = false
    local lastGunScan = 0
    while running do
        if utility.walkEnabled or utility.jumpEnabled then applyCharacterMods() end
        if utility.autoGrab or utility.gunAura or utility.notifyDropped or utility.notifyPickup then
            local now = os.clock()
            if now - lastGunScan >= 0.5 then
                lastGunScan = now
                local active = gunRoundActive()
                -- Reset the edge detector in the lobby.  This prevents a stale
                -- GunDrop from alternating between “dropped” and “picked up”
                -- notifications while the player is dead or waiting.
                if not active then
                    hadDrop = false
                else
                    local gun = findDroppedGun()
                    local root = localRoot()
                    local closeEnough = gun and root and (root.Position - gun.Position).Magnitude <= (utility.gunAuraRange or 10)
                    local shouldGrab = gun and not localHasGun() and (utility.autoGrab or (utility.gunAura and closeEnough))
                    if shouldGrab then grabGun(true) end
                    if utility.notifyDropped and gun and not hadDrop then notify("Dropped gun detected", 3) end
                    if utility.notifyPickup and not gun and hadDrop then notify("Gun picked up", 3) end
                    hadDrop = gun ~= nil
                end
            end
        end
        if utility.touchFling then
            local root = localRoot()
            if root then
                local old = root.AssemblyLinearVelocity
                pcall(function() root.AssemblyLinearVelocity = old * utility.touchPower + Vector3.new(0, utility.touchPower, 0) end)
                RunService.RenderStepped:Wait()
                if root.Parent then pcall(function() root.AssemblyLinearVelocity = old end) end
            end
        end
        if utility.antiFling then
            applyAntiFling()
            for _, player in ipairs(getPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end
        if utility.autoFlingSheriff and not flingBusy then
            local p = findSheriff(); if p then flingPlayer(p) end
        end
        if utility.autoFlingMurderer and not flingBusy then
            local p = validTarget(murderer) and murderer or findByKnife(); if p then flingPlayer(p) end
        end
        if utility.flingAll and not flingBusy then
            for _, player in ipairs(getPlayers()) do
                if not utility.flingAll then break end
                if player ~= LocalPlayer then flingPlayer(player) end
            end
        end
        task.wait(.15)
    end
end)

-- chat spam loop
task.spawn(function()
    while running do
        if utility.chatSpam and utility.chatMessage ~= "" then
            sendChat(utility.chatMessage)
            task.wait(math.clamp(utility.chatDelay or 3, 1, 60))
        else
            task.wait(0.5)
        end
    end
end)

--======================================================== PRESET SYSTEM
function cleanPresetName(name)
    name = tostring(name or "default"):gsub("%.preset$", ""):gsub("[^%w_%- ]", "_")
    return name ~= "" and name or "default"
end
function ensurePresetFolder()
    if type(makefolder) ~= "function" then return end
    if type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, PRESET_FOLDER)
        if ok and exists then return end
    end
    pcall(makefolder, PRESET_FOLDER)
end
function xorPreset(data)
    local output = table.create(#data)
    for index = 1, #data do
        output[index] = string.char(bit32.bxor(string.byte(data, index), 40))
    end
    return table.concat(output)
end
function exportRevertConfig()
    return {
        cfg = {
            predict_jump = config.predictJump,
            prediction_ping = config.manualPingMs,
            y_pos_offset = config.offsetY / 100,
            prioritize_your_ping = config.prioritizePing,
            horizontal_multiplier = config.horizontalMultiplier / 100,
            vertical_multiplier = config.verticalMultiplier / 100,
            max_simulation_time = config.maxSimulationMs,
            interval = config.predictionIntervalMs / 10000,
            z_pos_offset = config.offsetZ / 100,
            predict_lag = config.predictLag,
            x_pos_offset = config.offsetX / 100,
        },
        noir = {
            targetMode = config.targetMode, hitPart = config.hitPart, fovSize = config.fovSize,
            shotMethod = config.shotMethod, autoFire = config.autoFire, wallCheck = config.wallCheck, ignoreDead = config.ignoreDead,
            ignoreFriends = config.ignoreFriends, maxDistance = config.maxDistance,
            adaptive = config.adaptive, fixedLead = config.fixedLead, extraLead = config.extraLead,
            maxLead = config.maxLead, alignDirection = config.alignDirection,
            knifeWallCheck = config.knifeWallCheck,
            knifePrioritizeSheriff = config.knifePrioritizeSheriff, knifeAutoThrow = config.knifeAutoThrow,
        },
        author = LocalPlayer.Name,
        game = "Murder Mystery 2",
        category = "gun",
    }
end
function applyRevertConfig(data)
    if typeof(data) ~= "table" then return false end
    local cfg = data.cfg
    if typeof(cfg) == "table" then
        if typeof(cfg.predict_jump) == "boolean" then config.predictJump = cfg.predict_jump end
        if typeof(cfg.prediction_ping) == "number" then config.manualPingMs = cfg.prediction_ping end
        if typeof(cfg.prioritize_your_ping) == "boolean" then config.prioritizePing = cfg.prioritize_your_ping end
        if typeof(cfg.horizontal_multiplier) == "number" then config.horizontalMultiplier = cfg.horizontal_multiplier * 100 end
        if typeof(cfg.vertical_multiplier) == "number" then config.verticalMultiplier = cfg.vertical_multiplier * 100 end
        if typeof(cfg.max_simulation_time) == "number" then config.maxSimulationMs = cfg.max_simulation_time end
        if typeof(cfg.interval) == "number" then config.predictionIntervalMs = cfg.interval * 10000 end
        if typeof(cfg.x_pos_offset) == "number" then config.offsetX = cfg.x_pos_offset * 100 end
        if typeof(cfg.y_pos_offset) == "number" then config.offsetY = cfg.y_pos_offset * 100 end
        if typeof(cfg.z_pos_offset) == "number" then config.offsetZ = cfg.z_pos_offset * 100 end
        if typeof(cfg.predict_lag) == "boolean" then config.predictLag = cfg.predict_lag end
    end
    local noir = data.noir
    if typeof(noir) == "table" then
        for _, key in ipairs({ "targetMode", "hitPart" }) do
            if typeof(noir[key]) == "string" then config[key] = noir[key] end
        end
        if noir.shotMethod == "Remote" or noir.shotMethod == "CFrame" then
            config.shotMethod = noir.shotMethod
        end
        for _, key in ipairs({ "fovSize", "maxDistance", "fixedLead", "extraLead", "maxLead" }) do
            if typeof(noir[key]) == "number" then config[key] = noir[key] end
        end
        for _, key in ipairs({ "autoFire", "wallCheck", "ignoreDead", "ignoreFriends", "adaptive", "alignDirection",
                               "knifeWallCheck", "knifePrioritizeSheriff", "knifeAutoThrow" }) do
            if typeof(noir[key]) == "boolean" then config[key] = noir[key] end
        end
    end
    return true
end
local presetNames
function savePreset()
    if type(writefile) ~= "function" then notify("Executor does not support writefile", 4) return end
    ensurePresetFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(exportRevertConfig()) end)
    if ok then
        local wrote, err = pcall(writefile, PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset", xorPreset(encoded))
        if wrote then
            notify("Preset saved: " .. cleanPresetName(presetName), 3)
            if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(presetNames(), cleanPresetName(presetName)) end
        else notify("Preset save failed: " .. tostring(err), 4) end
    else notify("Preset encode failed", 4) end
end
function loadPreset()
    if type(readfile) ~= "function" then notify("Executor does not support readfile", 4) return end
    local path = PRESET_FOLDER .. "/" .. cleanPresetName(presetName) .. ".preset"
    local ok, decoded = pcall(function()
        local raw = readfile(path)
        return HttpService:JSONDecode(xorPreset(raw))
    end)
    if ok and applyRevertConfig(decoded) then
        if type(syncRevertControls) == "function" then syncRevertControls() end
        notify("Preset loaded: " .. cleanPresetName(presetName), 3)
    else notify("Preset not found or invalid: " .. cleanPresetName(presetName), 4) end
end
presetNames = function()
    local names = { "default" }
    if type(listfiles) == "function" then
        ensurePresetFolder()
        local ok, files = pcall(listfiles, PRESET_FOLDER)
        if ok and typeof(files) == "table" then
            for _, file in ipairs(files) do
                local normalized = tostring(file):gsub("\\", "/")
                local name = normalized:match("([^/]+)%.preset$")
                if name and not table.find(names, name) then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return names
end

--========================================================= UI SECTIONS
local tab = host.CreateTab()

-- MAIN • SELF MODS
local selfMods = tab:AddSection("MAIN \u{2022} SELF MODS", "Universal player controls")
selfMods:AddToggle("Enable WalkSpeed", function(v) utility.walkEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("WalkSpeed", 8, 100, 16, function(v) utility.walkSpeed = v; applyCharacterMods() end)
selfMods:AddToggle("Enable JumpPower", function(v) utility.jumpEnabled = v; applyCharacterMods() end)
selfMods:AddSlider("JumpPower", 25, 150, 50, function(v) utility.jumpPower = v; applyCharacterMods() end)
selfMods:AddToggle("Anti AFK", function(v) utility.antiAfk = v end)
selfMods:AddToggle("Performance Mode", function(v) perfMode = v; notify(v and "Performance mode ON" or "Performance mode OFF", 2) end)
selfMods:AddButton("FPS Boost", fpsBoost)
selfMods:AddButton("Less Lag", lessLag)
selfMods:AddButton("Remove Barriers", removeBarriers)
selfMods:AddButton("Rejoin Server", rejoin)
selfMods:AddButton("Server Hop", serverHop)

-- MAIN • SERVER
local serverMods = tab:AddSection("MAIN \u{2022} SERVER", "MM2 round information")
serverMods:AddToggle("Show Round Timer", setRoundTimerVisible)
serverMods:AddToggle("Instant Role Detection", function(v) instantRoleDetection = v; if v then task.spawn(refreshTarget) end end)
serverMods:AddToggle("Auto Notify Roles", function(v) autoNotifyRoles = v; if not v then table.clear(announcedRoles) else task.spawn(refreshTarget) end end)
serverMods:AddButton("Show Murderer Chance", showMurdererChance)
serverMods:AddButton("Refresh Roles", refreshTarget)
serverMods:AddLabel("Roles are sampled during the 10 second countdown.")

-- WORLD • GUN
local worldGun = tab:AddSection("WORLD \u{2022} GUN", "Gun pickup and dropped gun controls")
worldGun:AddButton("Grab Gun", function() grabGun() end)
worldGun:AddToggle("Auto Grab Gun", function(v) utility.autoGrab = v end)
worldGun:AddToggle("Auto Grab Gun Safety Check", function(v) utility.grabSafety = v end)
worldGun:AddToggle("Gun Aura", function(v) utility.gunAura = v end)
worldGun:AddSlider("Gun Aura Range", 5, 40, 10, function(v) utility.gunAuraRange = v end)
worldGun:AddToggle("Auto Notify on Dropped Gun", function(v) utility.notifyDropped = v end)
worldGun:AddToggle("Gun Pickup Notify", function(v) utility.notifyPickup = v end)

-- WORLD • FLING
local worldFling = tab:AddSection("WORLD \u{2022} FLING", "Sheriff, Murderer and selected player")
worldFling:AddButton("Fling Sheriff", function() local p = findSheriff(); if p then task.spawn(flingPlayer, p) else notify("Sheriff not found", 2) end end)
worldFling:AddButton("Fling Murder", function() local p = validTarget(murderer) and murderer or findByKnife(); if p then task.spawn(flingPlayer, p) else notify("Murderer not found", 2) end end)
local selectedPlayerControl = worldFling:AddDropdown("Select Player", playerNameList(), function(name)
    utility.selectedPlayer = name ~= "None" and name or nil
    config.selectedPlayer = utility.selectedPlayer
end)
worldFling:AddButton("Fling Selected", function() local p = utility.selectedPlayer and Players:FindFirstChild(utility.selectedPlayer); if p then task.spawn(flingPlayer, p) else notify("Select a player", 2) end end)
worldFling:AddButton("Refresh Player List", function() if selectedPlayerControl and selectedPlayerControl.Refresh then selectedPlayerControl:Refresh(playerNameList(), utility.selectedPlayer or "None") end end)

-- WORLD • TOUCH FLING
local touchFlingSection = tab:AddSection("WORLD \u{2022} TOUCH FLING", "Adapted from FlingGui")
touchFlingSection:AddToggle("Touch Fling", function(v) utility.touchFling = v end)
touchFlingSection:AddSlider("Touch Fling Power", 10, 50000, 100, function(v) utility.touchPower = v end)

-- WORLD • FLING SETTINGS
local flingSettings = tab:AddSection("WORLD \u{2022} FLING SETTINGS", "Automatic fling and power settings")
flingSettings:AddButton("Fling Nearest", function() task.spawn(flingPlayer, nearestPlayer()) end)
flingSettings:AddToggle("Auto Fling Sheriff / Hero", function(v) utility.autoFlingSheriff = v end)
flingSettings:AddToggle("Auto Fling Murderer", function(v) utility.autoFlingMurderer = v end)
flingSettings:AddToggle("Fling All", function(v) utility.flingAll = v end)
flingSettings:AddToggle("Anti Fling", function(v) utility.antiFling = v end)
flingSettings:AddSlider("Fling Duration", 1, 5, 2, function(v) utility.flingDuration = v end)
flingSettings:AddSlider("Fling Power", 1, 3, 1, function(v) utility.flingPower = v end)

-- Silent Aim
local main = tab:AddSection("Silent Aim", "Gun aim assist")
main:AddToggle("Enabled", toggle)
main:AddDropdown("Shot Method", { "Remote", "CFrame" }, function(v)
    config.shotMethod = (v == "CFrame") and "CFrame" or "Remote"
end)
main:AddKeybind("Aim Key", "None", function(k) config.aimKey = k; aimHeld = (k == "None") end)
main:AddKeybind("Toggle Key", "None", function(k) config.toggleKey = k end)
main:AddToggle("Wall Check", function(v) config.wallCheck = v end)
main:AddToggle("Show Shoot Murder Button", setShootButtonVisible)
main:AddToggle("Lock Shoot Murder Button", function(v) config.lockShootButton = v end)

-- Knife Silent Aim
local knifeSection = tab:AddSection("Knife Silent Aim", "Knife throw / stab aim assist")
knifeSection:AddToggle("Knife Silent Aim", function(v)
    config.knifeEnabled = v
    if v then
        installHook()
        task.spawn(refreshTarget)
    end
end)
knifeSection:AddToggle("Knife Wall Check", function(v) config.knifeWallCheck = v end)
knifeSection:AddToggle("Prioritize Sheriff", function(v) config.knifePrioritizeSheriff = v end)
knifeSection:AddToggle("Auto Throw Knife", function(v) config.knifeAutoThrow = v end)

-- VISUAL • PLAYER OUTLINE
local playerOutline = tab:AddSection("VISUAL \u{2022} PLAYER OUTLINE", "Role-colored silhouettes")
playerOutline:AddToggle("Everyone", function(v) config.espOutline = v; task.spawn(refreshTarget); refreshESP() end)
playerOutline:AddToggle("Murderer Only", function(v) config.espOutlineMurderer = v; task.spawn(refreshTarget); refreshESP() end)
playerOutline:AddToggle("Sheriff / Hero Only", function(v) config.espOutlineSheriff = v; task.spawn(refreshTarget); refreshESP() end)
playerOutline:AddToggle("Chams Everyone", function(v) config.espChams = v; refreshESP() end)
playerOutline:AddToggle("Chams Murderer", function(v) config.espChamsMurderer = v; refreshESP() end)
playerOutline:AddToggle("Chams Sheriff / Hero", function(v) config.espChamsSheriff = v; refreshESP() end)

-- VISUAL • PLAYER BOX
local playerBox = tab:AddSection("VISUAL \u{2022} PLAYER BOX", "Clean role-colored boxes")
playerBox:AddToggle("Everyone", function(v) config.espBox = v; task.spawn(refreshTarget); refreshESP() end)
playerBox:AddToggle("Murderer Only", function(v) config.espBoxMurderer = v; task.spawn(refreshTarget); refreshESP() end)
playerBox:AddToggle("Sheriff / Hero Only", function(v) config.espBoxSheriff = v; task.spawn(refreshTarget); refreshESP() end)
playerBox:AddToggle("Show Name", function(v) config.espName = v; refreshESP() end)
playerBox:AddToggle("Show Distance", function(v) config.espDistance = v; refreshESP() end)
playerBox:AddToggle("Show Health", function(v) config.espHealth = v; refreshESP() end)
playerBox:AddToggle("Show Role", function(v) config.espRole = v; refreshESP() end)
playerBox:AddToggle("Show Tracer", function(v) config.espTracer = v end)
playerBox:AddToggle("Show Skeleton", function(v) config.espSkeleton = v end)

-- VISUAL • OBJECT OUTLINE
local objectOutline = tab:AddSection("VISUAL \u{2022} OBJECT OUTLINE", "Dropped items and map objects")
objectOutline:AddToggle("Dropped Gun", function(v) config.outlineDroppedGun = v; refreshObjectESP() end)
objectOutline:AddToggle("Traps", function(v) config.outlineTraps = v; refreshObjectESP() end)
objectOutline:AddToggle("Throwing Knives", function(v) config.outlineThrowingKnives = v; refreshObjectESP() end)
objectOutline:AddToggle("Coins", function(v) config.outlineCoins = v; refreshObjectESP() end)

-- VISUAL • OBJECT BOX
local objectBox = tab:AddSection("VISUAL \u{2022} OBJECT BOX", "Compact object boxes")
objectBox:AddToggle("Dropped Gun", function(v) config.boxDroppedGun = v; refreshObjectESP() end)
objectBox:AddToggle("Traps", function(v) config.boxTraps = v; refreshObjectESP() end)
objectBox:AddToggle("Throwing Knives", function(v) config.boxThrowingKnives = v; refreshObjectESP() end)
objectBox:AddToggle("Coins", function(v) config.boxCoins = v; refreshObjectESP() end)

-- NOIR CONFIG
local revert = tab:AddSection("NOIR CONFIG", "Standalone Silent Aim settings; .preset-compatible")
presetDropdown = revert:AddDropdown("Your Presets", presetNames(), function(value) presetName = cleanPresetName(value) end)
revert:AddTextBox("Preset Name", function(value) presetName = cleanPresetName(value) end)
revert:AddButton("Save Preset", savePreset)
revert:AddButton("Load Preset", loadPreset)
revert:AddButton("Refresh Presets", function()
    if presetDropdown and presetDropdown.Refresh then presetDropdown:Refresh(presetNames(), cleanPresetName(presetName)) end
end)

function addTrackedToggle(key, label, callback)
    local control = revert:AddToggle(label, function(value)
        revertToggleStates[key] = value
        callback(value)
    end)
    revertControls[key] = control
    return control
end
function addTrackedSlider(key, label, minimum, maximum, default, callback)
    local control = revert:AddSlider(label, minimum, maximum, default, function(value)
        callback(tonumber(value) or default)
    end)
    revertControls[key] = control
    return control
end

addTrackedToggle("prioritizePing", "Prioritize Your Ping", function(value) config.prioritizePing = value end)
addTrackedToggle("predictJump", "Predict Jump", function(value) config.predictJump = value end)
addTrackedToggle("predictLag", "Predict Lag", function(value) config.predictLag = value end)
addTrackedToggle("adaptive", "Adaptive Lead", function(value) config.adaptive = value end)
addTrackedSlider("maxSimulationMs", "Prediction Max Simulation Time", 20, 300, 180, function(value) config.maxSimulationMs = value end)
addTrackedSlider("predictionIntervalMs", "Prediction Interval", 1, 100, 72, function(value) config.predictionIntervalMs = value end)
addTrackedSlider("manualPingMs", "Prediction Ping", 10, 350, 80, function(value) config.manualPingMs = value end)
addTrackedSlider("offsetX", "X Position Offset (%)", -100, 100, 0, function(value) config.offsetX = value end)
addTrackedSlider("offsetY", "Y Position Offset (%)", -100, 100, 0, function(value) config.offsetY = value end)
addTrackedSlider("offsetZ", "Z Position Offset (%)", -100, 100, 0, function(value) config.offsetZ = value end)
addTrackedSlider("horizontalMultiplier", "Prediction Horizontal Multiplier (%)", 0, 400, 100, function(value) config.horizontalMultiplier = value end)
addTrackedSlider("verticalMultiplier", "Prediction Vertical Multiplier (%)", 0, 400, 100, function(value) config.verticalMultiplier = value end)

syncRevertControls = function(syncToggles)
    if syncToggles ~= false then
        for _, key in ipairs({ "prioritizePing", "predictJump", "predictLag", "adaptive" }) do
            local desired = config[key] == true
            local toggleControl = revertControls[key]
            if type(toggleControl) == "function" and revertToggleStates[key] ~= desired then pcall(toggleControl) end
        end
    end
    for _, key in ipairs({ "maxSimulationMs", "predictionIntervalMs", "manualPingMs", "offsetX", "offsetY", "offsetZ", "horizontalMultiplier", "verticalMultiplier" }) do
        local control = revertControls[key]
        if type(control) == "table" and type(control.SetValue) == "function" then pcall(control.SetValue, control, config[key])
        elseif type(control) == "function" then pcall(control, config[key]) end
    end
end

--===================================================== EVENT CONNECTIONS
local remoteConnections = {}
function connectRemote(name, handler)
    local wanted = string.lower(tostring(name))
    local first
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if string.lower(remote.Name) == wanted then
            if remote:IsA("RemoteEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.OnClientEvent:Connect(function(...) pcall(handler, ...) end))
            elseif remote:IsA("BindableEvent") then
                first = first or remote
                table.insert(remoteConnections, remote.Event:Connect(function(...) pcall(handler, ...) end))
            end
        end
    end
    return first
end

connectRemote("PlayerDataChanged", function(data) consumeData(data) end)
connectRemote("RoundStart", function(timerValue)
    local roundLength = tonumber(timerValue)
    beginRoundTimer(roundLength)
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
    task.spawn(refreshTarget)
end)
local function finishRound()
    resetRoundTimer()
    murderer, sheriff, hero = nil, nil, nil
    table.clear(roleCache); table.clear(announcedRoles)
    if type(refreshESP) == "function" then refreshESP() end
end
connectRemote("RoundEndFade", finishRound)
connectRemote("RoundEnd", finishRound)
connectRemote("RoleSelect", function() task.spawn(refreshTarget) end)
connectRemote("ShowRoleSelect", function() task.spawn(refreshTarget) end)
connectRemote("ShowRoleSelectNew", function() task.spawn(refreshTarget) end)
connectRemote("ChangeTarget", function() task.spawn(refreshTarget) end)
connectRemote("GiveWeapon", function() task.spawn(refreshTarget) end)
connectRemote("KillEvent", function() task.spawn(refreshTarget) end)
connectRemote("GameOver", finishRound)
connectRemote("VictoryScreen", finishRound)
connectRemote("Stealth", function() notify("Stealth activated", 3) end)
--======================================================== BACKGROUND LOOPS
task.spawn(function()
    while running do
        updatePing()
        autoTuneForPing()
        task.wait(0.5)
    end
end)

task.spawn(function()
    while running do
        refreshTarget()
        task.wait(instantRoleDetection and 0.5 or 2)
    end
end)

task.spawn(function()
    while running do
        -- Only sample motion while an aim feature is active; run at ~30 Hz instead of every frame.
        if config.enabled or config.knifeEnabled then
            local part = targetPart()
            if part then sampleMotion(part) end
        end
        task.wait(1 / 30)
    end
end)

--======================================================== KEYBINDS
aimHeld = (config.aimKey == "None")
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = true end
        if key == config.autoFireKey then autoFireHeld = true end
        if key == config.toggleKey and config.toggleKey ~= "None" then toggle(not config.enabled) end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "MouseButton1" then aimHeld = true end
        if config.autoFireKey == "MouseButton1" then autoFireHeld = true end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == config.aimKey then aimHeld = false end
        if key == config.autoFireKey then autoFireHeld = false end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if config.aimKey == "MouseButton1" then aimHeld = false end
        if config.autoFireKey == "MouseButton1" then autoFireHeld = false end
    end
end)

--======================================================== NAV WIRING
refreshCanvas()

--====================================================== INTRO ANIMATION
task.defer(function()
    RunService.RenderStepped:Wait()
    if not win.Parent then return end
    local targetPosition = win.Position
    win.Position = targetPosition + UDim2.fromOffset(0, 32)
    win.BackgroundTransparency = 1
    win.Rotation = -1.2
    winScale.Scale = .68
    win.Visible = true
    TweenService:Create(win, TweenInfo.new(.56, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = targetPosition, BackgroundTransparency = .04, Rotation = 0 }):Play()
    TweenService:Create(winScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

notify("v4 ready \u{2022} " .. tostring(#getPlayers()) .. " players in server", 4)

--==================================================== EMBEDDED WORLD PLUGINS
-- Compatibility bridge for the four attached ODH plugins. Each plugin is
-- isolated and guarded so one unsupported feature cannot stop the main UI.
do
    local function makeWorldPluginTab(base)
        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                if key == "AddSection" then
                    return function(_, name, description)
                        name = tostring(name or "Plugin")
                        if string.sub(name, 1, 6) ~= "WORLD " then
                            name = "WORLD \u{2022} " .. name
                        end
                        return base:AddSection(name, description or "")
                    end
                end
                local method = base[key]
                if type(method) == "function" then
                    return function(_, ...)
                        return method(base, ...)
                    end
                end
                return method
            end,
        })
        return proxy
    end
    local odh_shared_plugins = {
        game_name = "Murder Mystery 2",
        CreateTab = function(_, title, icon)
            return makeWorldPluginTab(host.CreateTab())
        end,
        Notify = function(textValue, duration)
            notify(tostring(textValue), duration or 3)
        end,
    }
    -- ================================================================
    -- EMBEDDED PLUGIN: Anims.lua.txt
    do
        local __pluginOk, __pluginError = xpcall(function()
-- FE Animations: current Overdrive H API + persistent preferences.
-- Revision 3: full track reset before ID changes + delayed, supersession-safe Animate restart.
-- Animation presets by aux0on: https://github.com/aux0on/FE/blob/main/Anims.lua
-- R15 only. Asset availability/replication depends on Roblox and the experience.
-- Self-contained: does not download or execute the old external CrashHandler.
local shared = odh_shared_plugins
if not shared or type(shared.CreateTab) ~= "function" then
    warn("[FE Animations] Load this file through the current Overdrive H plugin menu.")
    return
end
local KEY = "ODH_FEAnimationsRuntime_v2"
if type(_G[KEY]) == "table" and _G[KEY].alive then
    if type(shared.Notify)=="function" then
        pcall(shared.Notify,"FE Animations is already loaded. Use its existing tab.",4)
    end
    return
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("[FE Animations] LocalPlayer unavailable."); return end
local HttpService = game:GetService("HttpService")
local runtime = {version=3,alive=true, initializing=true, enabled=false, generation=0,
    selections={all="Default",idle="Default",walk="Default",run="Default",jump="Default",climb="Default",fall="Default"}}
local FILE = "ODH_FEAnimations_settings.json"
runtime.settingsFile=FILE
local warnings={}
local function WarnOnce(key,text)
    if warnings[key] then return end
    warnings[key]=true
    warn("[FE Animations] "..text)
    if type(shared.Notify)=="function" then pcall(shared.Notify,"FE Animations: "..text,5) end
end
local environment={}
if type(getgenv)=="function" then
    local ok,result=pcall(getgenv)
    if ok and type(result)=="table" then environment=result end
end
local fileRead=type(readfile)=="function" and readfile or environment.readfile
local fileWrite=type(writefile)=="function" and writefile or environment.writefile
local fileExists=type(isfile)=="function" and isfile or environment.isfile
local canPersist=type(fileRead)=="function" and type(fileWrite)=="function"
runtime.saveStatus=canPersist and "Not saved" or "Unavailable"

local animPresets = {
    ["Default"] = nil,
    ["OG Rthro Run"] = {run = "http://www.roblox.com/asset/?id=9801814462"},
    ["Vampire"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083445855",
        idle2 = "http://www.roblox.com/asset/?id=1083450166",
        walk  = "http://www.roblox.com/asset/?id=1083473930",
        run   = "http://www.roblox.com/asset/?id=1083462077",
        jump  = "http://www.roblox.com/asset/?id=1083455352",
        climb = "http://www.roblox.com/asset/?id=1083439238",
        fall  = "http://www.roblox.com/asset/?id=1083443587"
    },
    ["Hero"] = {
        idle1 = "http://www.roblox.com/asset/?id=616111295",
        idle2 = "http://www.roblox.com/asset/?id=616113536",
        walk  = "http://www.roblox.com/asset/?id=616122287",
        run   = "http://www.roblox.com/asset/?id=616117076",
        jump  = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall  = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Zombie Classic"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk  = "http://www.roblox.com/asset/?id=616168032",
        run   = "http://www.roblox.com/asset/?id=616163682",
        jump  = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall  = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Mage"] = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk  = "http://www.roblox.com/asset/?id=707897309",
        run   = "http://www.roblox.com/asset/?id=707861613",
        jump  = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall  = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Ghost"] = {
        idle1 = "http://www.roblox.com/asset/?id=616006778",
        idle2 = "http://www.roblox.com/asset/?id=616008087",
        walk  = "http://www.roblox.com/asset/?id=616010382",
        run   = "http://www.roblox.com/asset/?id=616013216",
        jump  = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall  = "http://www.roblox.com/asset/?id=616005863"
    },
    ["Elder"] = {
        idle1 = "http://www.roblox.com/asset/?id=845397899",
        idle2 = "http://www.roblox.com/asset/?id=845400520",
        walk  = "http://www.roblox.com/asset/?id=845403856",
        run   = "http://www.roblox.com/asset/?id=845386501",
        jump  = "http://www.roblox.com/asset/?id=845398858",
        climb = "http://www.roblox.com/asset/?id=845392038",
        fall  = "http://www.roblox.com/asset/?id=845396048"
    },
    ["Levitation"] = {
        idle1 = "http://www.roblox.com/asset/?id=616006778",
        idle2 = "http://www.roblox.com/asset/?id=616008087",
        walk  = "http://www.roblox.com/asset/?id=616013216",
        run   = "http://www.roblox.com/asset/?id=616010382",
        jump  = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall  = "http://www.roblox.com/asset/?id=616005863"
    },
    ["Astronaut"] = {
        idle1 = "http://www.roblox.com/asset/?id=891621366",
        idle2 = "http://www.roblox.com/asset/?id=891633237",
        walk  = "http://www.roblox.com/asset/?id=891667138",
        run   = "http://www.roblox.com/asset/?id=891636393",
        jump  = "http://www.roblox.com/asset/?id=891627522",
        climb = "http://www.roblox.com/asset/?id=891609353",
        fall  = "http://www.roblox.com/asset/?id=891617961"
    },
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk  = "http://www.roblox.com/asset/?id=656121766",
        run   = "http://www.roblox.com/asset/?id=656118852",
        jump  = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall  = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Werewolf"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083195517",
        idle2 = "http://www.roblox.com/asset/?id=1083214717",
        walk  = "http://www.roblox.com/asset/?id=1083178339",
        run   = "http://www.roblox.com/asset/?id=1083216690",
        jump  = "http://www.roblox.com/asset/?id=1083218792",
        climb = "http://www.roblox.com/asset/?id=1083182000",
        fall  = "http://www.roblox.com/asset/?id=1083189019"
    },
    ["Cartoon"] = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk  = "http://www.roblox.com/asset/?id=742640026",
        run   = "http://www.roblox.com/asset/?id=742638842",
        jump  = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall  = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Pirate"] = {
        idle1 = "http://www.roblox.com/asset/?id=750781874",
        idle2 = "http://www.roblox.com/asset/?id=750782770",
        walk  = "http://www.roblox.com/asset/?id=750785693",
        run   = "http://www.roblox.com/asset/?id=750783738",
        jump  = "http://www.roblox.com/asset/?id=750782230",
        climb = "http://www.roblox.com/asset/?id=750779899",
        fall  = "http://www.roblox.com/asset/?id=750780242"
    },
    ["Sneaky"] = {
        idle1 = "http://www.roblox.com/asset/?id=1132473842",
        idle2 = "http://www.roblox.com/asset/?id=1132477671",
        walk  = "http://www.roblox.com/asset/?id=1132510133",
        run   = "http://www.roblox.com/asset/?id=1132494274",
        jump  = "http://www.roblox.com/asset/?id=1132489853",
        climb = "http://www.roblox.com/asset/?id=1132461372",
        fall  = "http://www.roblox.com/asset/?id=1132469004"
    },
    ["Toy"] = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782845736",
        walk  = "http://www.roblox.com/asset/?id=782843345",
        run   = "http://www.roblox.com/asset/?id=782842708",
        jump  = "http://www.roblox.com/asset/?id=782847020",
        climb = "http://www.roblox.com/asset/?id=782843869",
        fall  = "http://www.roblox.com/asset/?id=782846423"
    },
    ["Knight"] = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk  = "http://www.roblox.com/asset/?id=657552124",
        run   = "http://www.roblox.com/asset/?id=657564596",
        jump  = "http://www.roblox.com/asset/?id=658409194",
        climb = "http://www.roblox.com/asset/?id=658360781",
        fall  = "http://www.roblox.com/asset/?id=657600338"
    },
    ["Confident"] = {
        idle1 = "http://www.roblox.com/asset/?id=1069977950",
        idle2 = "http://www.roblox.com/asset/?id=1069987858",
        walk  = "http://www.roblox.com/asset/?id=1070017263",
        run   = "http://www.roblox.com/asset/?id=1070001516",
        jump  = "http://www.roblox.com/asset/?id=1069984524",
        climb = "http://www.roblox.com/asset/?id=1069946257",
        fall  = "http://www.roblox.com/asset/?id=1069973677"
    },
    ["Popstar"] = {
        idle1 = "http://www.roblox.com/asset/?id=1212900985",
        idle2 = "http://www.roblox.com/asset/?id=1212900985",
        walk  = "http://www.roblox.com/asset/?id=1212980338",
        run   = "http://www.roblox.com/asset/?id=1212980348",
        jump  = "http://www.roblox.com/asset/?id=1212954642",
        climb = "http://www.roblox.com/asset/?id=1213044953",
        fall  = "http://www.roblox.com/asset/?id=1212900995"
    },
    ["Princess"] = {
        idle1 = "http://www.roblox.com/asset/?id=941003647",
        idle2 = "http://www.roblox.com/asset/?id=941013098",
        walk  = "http://www.roblox.com/asset/?id=941028902",
        run   = "http://www.roblox.com/asset/?id=941015281",
        jump  = "http://www.roblox.com/asset/?id=941008832",
        climb = "http://www.roblox.com/asset/?id=940996062",
        fall  = "http://www.roblox.com/asset/?id=941000007"
    },
    ["Cowboy"] = {
        idle1 = "http://www.roblox.com/asset/?id=1014390418",
        idle2 = "http://www.roblox.com/asset/?id=1014398616",
        walk  = "http://www.roblox.com/asset/?id=1014421541",
        run   = "http://www.roblox.com/asset/?id=1014401683",
        jump  = "http://www.roblox.com/asset/?id=1014394726",
        climb = "http://www.roblox.com/asset/?id=1014380606",
        fall  = "http://www.roblox.com/asset/?id=1014384571"
    },
    ["Patrol"] = {
        idle1 = "http://www.roblox.com/asset/?id=1149612882",
        idle2 = "http://www.roblox.com/asset/?id=1150842221",
        walk  = "http://www.roblox.com/asset/?id=1151231493",
        run   = "http://www.roblox.com/asset/?id=1150967949",
        jump  = "http://www.roblox.com/asset/?id=1150944216",
        climb = "http://www.roblox.com/asset/?id=1148811837",
        fall  = "http://www.roblox.com/asset/?id=1148863382"
    },
    ["Zombie FE"] = {
        idle1 = "http://www.roblox.com/asset/?id=3489171152",
        idle2 = "http://www.roblox.com/asset/?id=3489171152",
        walk  = "http://www.roblox.com/asset/?id=3489174223",
        run   = "http://www.roblox.com/asset/?id=3489173414",
        jump  = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall  = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Catwalk Glam"] = {
        idle1 = "http://www.roblox.com/asset/?id=133806214992291",
        idle2 = "http://www.roblox.com/asset/?id=133806214992291",
        walk  = "http://www.roblox.com/asset/?id=109168724482748",
        run   = "http://www.roblox.com/asset/?id=81024476153754",
        jump  = "http://www.roblox.com/asset/?id=116936326516985",
        climb = "http://www.roblox.com/asset/?id=119377220967554",
        fall  = "http://www.roblox.com/asset/?id=92294537340807"
    },
    ["Amazon Unboxed"] = {
        idle1 = "http://www.roblox.com/asset/?id=98281136301627",
        idle2 = "http://www.roblox.com/asset/?id=98281136301627",
        walk  = "http://www.roblox.com/asset/?id=90478085024465",
        run   = "http://www.roblox.com/asset/?id=134824450619865",
        jump  = "http://www.roblox.com/asset/?id=121454505477205",
        climb = "http://www.roblox.com/asset/?id=121145883950231",
        fall  = "http://www.roblox.com/asset/?id=94788218468396"
    },
    ["Glow Motion"] = {
        idle1 = "https://www.roblox.com/asset/?id=137764781910579",
        idle2 = "https://www.roblox.com/asset/?id=137764781910579",
        walk  = "http://www.roblox.com/asset/?id=85809016093530",
        run   = "http://www.roblox.com/asset/?id=101925097435036",
        jump  = "http://www.roblox.com/asset/?id=74159004634379",
        climb = "http://www.roblox.com/asset/?id=108236155509584",
        fall  = "https://www.roblox.com/asset/?id=98070939608691"
    },
    ["Bubbly"] = {
        idle1 = "https://www.roblox.com/asset/?id=10921054344",
        idle2 = "https://www.roblox.com/asset/?id=10921054344",
        walk  = "http://www.roblox.com/asset/?id=10980888364",
        run   = "http://www.roblox.com/asset/?id=10921057244",
        jump  = "http://www.roblox.com/asset/?id=10921062673",
        climb = "http://www.roblox.com/asset/?id=10921053544",
        fall  = "https://www.roblox.com/asset/?id=10921061530"
    },
    ["Adidas Comm"] = {
        idle1 = "https://www.roblox.com/asset/?id=122257458498464",
        idle2 = "https://www.roblox.com/asset/?id=122257458498464",
        walk  = "http://www.roblox.com/asset/?id=122150855457006",
        run   = "http://www.roblox.com/asset/?id=82598234841035",
        jump  = "http://www.roblox.com/asset/?id=75290611992385",
        climb = "http://www.roblox.com/asset/?id=88763136693023",
        fall  = "https://www.roblox.com/asset/?id=98600215928904"
    },
    ["KATSEYE"] = {
        idle1 = "https://www.roblox.com/asset/?id=108187809145790",
        idle2 = "https://www.roblox.com/asset/?id=108187809145790",
        walk  = "http://www.roblox.com/asset/?id=99182913548783",
        run   = "http://www.roblox.com/asset/?id=73117360545482",
        jump  = "http://www.roblox.com/asset/?id=103632305262747",
        climb = "http://www.roblox.com/asset/?id=106213237973858",
        fall  = "https://www.roblox.com/asset/?id=127802717128367"
    },
    ["Wicked Popular"] = {
        idle1 = "https://www.roblox.com/asset/?id=118832222982049",
        idle2 = "https://www.roblox.com/asset/?id=118832222982049",
        walk  = "http://www.roblox.com/asset/?id=92072849924640",
        run   = "http://www.roblox.com/asset/?id=72301599441680",
        jump  = "http://www.roblox.com/asset/?id=104325245285198",
        climb = "http://www.roblox.com/asset/?id=131326830509784",
        fall  = "https://www.roblox.com/asset/?id=121152442762481"
    },
    ["Dizzy"] = {
        idle1 = "http://www.roblox.com/asset/?id=132806359718468",
        idle2 = "http://www.roblox.com/asset/?id=132806359718468",
        walk  = "http://www.roblox.com/asset/?id=110106034100313",
        run   = "http://www.roblox.com/asset/?id=138305342272849",
        jump  = "http://www.roblox.com/asset/?id=108564434408211",
        climb = "http://www.roblox.com/asset/?id=93550710314258",
        fall  = "http://www.roblox.com/asset/?id=138967706335414"
    },
    ["WDTL"] = {
        idle1 = "http://www.roblox.com/asset/?id=92849173543269",
        idle2 = "http://www.roblox.com/asset/?id=92849173543269",
        walk  = "http://www.roblox.com/asset/?id=73718308412641",
        run   = "http://www.roblox.com/asset/?id=135515454877967",
        jump  = "http://www.roblox.com/asset/?id=78508480717326",
        climb = "http://www.roblox.com/asset/?id=129447497744818",
        fall  = "http://www.roblox.com/asset/?id=78147885297412"
    },
    ["Billie Eilish"] = {
        idle1 = "http://www.roblox.com/asset/?id=102934602884410",
        idle2 = "http://www.roblox.com/asset/?id=102934602884410",
        walk  = "http://www.roblox.com/asset/?id=81877886552514",
        run   = "http://www.roblox.com/asset/?id=100920560634123",
        jump  = "http://www.roblox.com/asset/?id=117602630922781",
        climb = "http://www.roblox.com/asset/?id=117873469361430",
        fall  = "http://www.roblox.com/asset/?id=81072141180299"
    },
    ["Cute Bouncy"] = {
        idle1 = "http://www.roblox.com/asset/?id=88464649697812",
        idle2 = "http://www.roblox.com/asset/?id=88464649697812",
        walk  = "http://www.roblox.com/asset/?id=98713727778027",
        run   = "http://www.roblox.com/asset/?id=133955346539948",
        jump  = "http://www.roblox.com/asset/?id=124147147418885",
        climb = "http://www.roblox.com/asset/?id=95542189442725",
        fall  = "http://www.roblox.com/asset/?id=128620818122982"
    },
    ["Cute"] = {
        idle1 = "http://www.roblox.com/asset/?id=85735421117197",
        idle2 = "http://www.roblox.com/asset/?id=85735421117197",
        walk  = "http://www.roblox.com/asset/?id=140409718187215",
        run   = "http://www.roblox.com/asset/?id=118375157537412",
        jump  = "http://www.roblox.com/asset/?id=132381016103721",
        climb = "http://www.roblox.com/asset/?id=86318575131600",
        fall  = "http://www.roblox.com/asset/?id=77496925287217"
    },
    ["Jolly"] = {
        idle1 = "http://www.roblox.com/asset/?id=136145727878709",
        idle2 = "http://www.roblox.com/asset/?id=136145727878709",
        walk  = "http://www.roblox.com/asset/?id=83277136078444",
        run   = "http://www.roblox.com/asset/?id=124419804298310",
        jump  = "http://www.roblox.com/asset/?id=122115816220842",
        climb = "http://www.roblox.com/asset/?id=107190574095036",
        fall  = "http://www.roblox.com/asset/?id=85263802503331"
    },
    ["Cute Kawaii"] = {
        idle1 = "http://www.roblox.com/asset/?id=72311682331639",
        idle2 = "http://www.roblox.com/asset/?id=72311682331639",
        walk  = "http://www.roblox.com/asset/?id=107212872423561",
        run   = "http://www.roblox.com/asset/?id=118582510545072",
        jump  = "http://www.roblox.com/asset/?id=112952548321695",
        climb = "http://www.roblox.com/asset/?id=126383408493776",
        fall  = "http://www.roblox.com/asset/?id=83307333809322"
    },
    ["Doll 3.0"] = {
        idle1 = "http://www.roblox.com/asset/?id=83032187271383",
        idle2 = "http://www.roblox.com/asset/?id=83032187271383",
        walk  = "http://www.roblox.com/asset/?id=78434960966537",
        run   = "http://www.roblox.com/asset/?id=129768396663808",
        jump  = "http://www.roblox.com/asset/?id=75369057994828",
        climb = "http://www.roblox.com/asset/?id=112371892133970",
        fall  = "http://www.roblox.com/asset/?id=81027444073311"
    },
    ["Victoria Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=132069965396465",
        idle2 = "http://www.roblox.com/asset/?id=132069965396465",
        walk  = "http://www.roblox.com/asset/?id=84814915379579",
        run   = "http://www.roblox.com/asset/?id=84814915379579",
        jump  = "http://www.roblox.com/asset/?id=78163261581163",
        climb = "http://www.roblox.com/asset/?id=87772134905508",
        fall  = "http://www.roblox.com/asset/?id=110073924253388"
    },
    ["Bike/Bicyclist"] = {
        idle1 = "http://www.roblox.com/asset/?id=126390120399173",
        idle2 = "http://www.roblox.com/asset/?id=136791517336633",
        walk  = "http://www.roblox.com/asset/?id=98707881660541",
        run   = "http://www.roblox.com/asset/?id=102775737211919",
        jump  = "http://www.roblox.com/asset/?id=129144847881258",
        climb = "http://www.roblox.com/asset/?id=88267082364595",
        fall  = "http://www.roblox.com/asset/?id=110684787086498"
    },
    ["Animal"] = {
        idle1 = "http://www.roblox.com/asset/?id=128838183008466",
        idle2 = "http://www.roblox.com/asset/?id=99689776099970",
        walk  = "http://www.roblox.com/asset/?id=112238064449133",
        run   = "http://www.roblox.com/asset/?id=97412731442167",
        jump  = "http://www.roblox.com/asset/?id=123565665274439",
        climb = "http://www.roblox.com/asset/?id=75085836535654",
        fall  = "http://www.roblox.com/asset/?id=124705831982259"
    },
    ["It-Girl Essential Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=132232079260125",
        idle2 = "http://www.roblox.com/asset/?id=102440789796215",
        walk  = "http://www.roblox.com/asset/?id=86579666661215",
        run   = "http://www.roblox.com/asset/?id=83336349930143",
        jump  = "http://www.roblox.com/asset/?id=103382156539106",
        climb = "http://www.roblox.com/asset/?id=77385815954046",
        fall  = "http://www.roblox.com/asset/?id=127262648208409"
    },
    ["Oldschool"] = {
        idle1 = "http://www.roblox.com/asset/?id=10921230744",
        idle2 = "http://www.roblox.com/asset/?id=10921232093",
        walk  = "http://www.roblox.com/asset/?id=10921244891",
        run   = "http://www.roblox.com/asset/?id=10921240218",
        jump  = "http://www.roblox.com/asset/?id=10921242013",
        climb = "http://www.roblox.com/asset/?id=10921229866",
        fall  = "http://www.roblox.com/asset/?id=10921241244"
    },
    ["Spider"] = {
        idle1 = "http://www.roblox.com/asset/?id=112316814377814",
        idle2 = "http://www.roblox.com/asset/?id=103439018552145",
        walk  = "http://www.roblox.com/asset/?id=109976439277879",
        run   = "http://www.roblox.com/asset/?id=119985832593347",
        jump  = "http://www.roblox.com/asset/?id=87979233462906",
        climb = "http://www.roblox.com/asset/?id=119278342251995",
        fall  = "http://www.roblox.com/asset/?id=71112238570777"
    },
    ["Joy"] = {
        idle1 = "http://www.roblox.com/asset/?id=119957475250242",
        idle2 = "http://www.roblox.com/asset/?id=101200477339169",
        walk  = "http://www.roblox.com/asset/?id=112597572150963",
        run   = "http://www.roblox.com/asset/?id=96521659811743",
        jump  = "http://www.roblox.com/asset/?id=82500357520736",
        climb = "http://www.roblox.com/asset/?id=110061716873830",
        fall  = "http://www.roblox.com/asset/?id=132095139090357"
    },
    ["Flying Aura"] = {
        idle1 = "http://www.roblox.com/asset/?id=122426844584505",
        idle2 = "http://www.roblox.com/asset/?id=122426844584505",
        walk  = "http://www.roblox.com/asset/?id=83077254246622",
        run   = "http://www.roblox.com/asset/?id=77053251062908",
        jump  = "http://www.roblox.com/asset/?id=125422018244301",
        climb = "http://www.roblox.com/asset/?id=95973965948476",
        fall  = "http://www.roblox.com/asset/?id=109790195947848"
    },
                
    ["FHA V2"] = {
        idle1 = "http://www.roblox.com/asset/?id=77320840005481",
        idle2 = "http://www.roblox.com/asset/?id=77320840005481",
        walk  = "http://www.roblox.com/asset/?id=134493251445479",
        run   = "http://www.roblox.com/asset/?id=122214533401932",
        jump  = "http://www.roblox.com/asset/?id=80078165493816",
        climb = "http://www.roblox.com/asset/?id=114562994724647",
        fall  = "http://www.roblox.com/asset/?id=98383265864436"
    },
   
    ["Silent Nurse"] = {
        idle1 = "http://www.roblox.com/asset/?id=111047244862844",
        idle2 = "http://www.roblox.com/asset/?id=111047244862844",
        walk  = "http://www.roblox.com/asset/?id=94196382152901",
        run   = "http://www.roblox.com/asset/?id=94196382152901",
        jump  = "http://www.roblox.com/asset/?id=106098057235980",
        climb = "http://www.roblox.com/asset/?id=108985375609705",
        fall  = "http://www.roblox.com/asset/?id=131579609334755"
    },

    ["Supermodel"] = {
        idle1 = "http://www.roblox.com/asset/?id=91917730726110",
        idle2 = "http://www.roblox.com/asset/?id=91917730726110",
        walk  = "http://www.roblox.com/asset/?id=90320132970213",
        run   = "http://www.roblox.com/asset/?id=112051258179255",
        jump  = "http://www.roblox.com/asset/?id=91931403363860",
        climb = "http://www.roblox.com/asset/?id=82728029306069",
        fall  = "http://www.roblox.com/asset/?id=119173466228299"
    },
    
    ["Enchanted Fairy"] = {
        idle1 = "http://www.roblox.com/asset/?id=73650178233095",
        idle2 = "http://www.roblox.com/asset/?id=73650178233095",
        walk  = "http://www.roblox.com/asset/?id=94547195663763",
        run   = "http://www.roblox.com/asset/?id=76909584337943",
        jump  = "http://www.roblox.com/asset/?id=120533712803667",
        climb = "http://www.roblox.com/asset/?id=140663406485180",
        fall  = "http://www.roblox.com/asset/?id=100947971756348"
    },
    
    ["Furry"] = {
        idle1 = "http://www.roblox.com/asset/?id=111821292044705",
        idle2 = "http://www.roblox.com/asset/?id=111821292044705",
        walk  = "http://www.roblox.com/asset/?id=104011441852459",
        run   = "http://www.roblox.com/asset/?id=87770060317862",
        jump  = "http://www.roblox.com/asset/?id=102635582722041",
        climb = "http://www.roblox.com/asset/?id=76660530164497",
        fall  = "http://www.roblox.com/asset/?id=137079985547592"
    },
    
    ["Vlada Model"] = {
        idle1 = "http://www.roblox.com/asset/?id=100139116433530",
        idle2 = "http://www.roblox.com/asset/?id=100139116433530",
        walk  = "http://www.roblox.com/asset/?id=77983757225444",
        run   = "http://www.roblox.com/asset/?id=116717848244930",
        jump  = "http://www.roblox.com/asset/?id=120751055172567",
        climb = "http://www.roblox.com/asset/?id=70966616077778",
        fall  = "http://www.roblox.com/asset/?id=136118518255777"
    },
    ["R6 Converter"] = {
        idle1 = "http://www.roblox.com/asset/?id=90040240627854",
        idle2 = "http://www.roblox.com/asset/?id=90040240627854",
        walk  = "http://www.roblox.com/asset/?id=92149852708428",
        run   = "http://www.roblox.com/asset/?id=72259383092959",
        jump  = "http://www.roblox.com/asset/?id=130519980521511",
        climb = "http://www.roblox.com/asset/?id=80369171706383",
        fall  = "http://www.roblox.com/asset/?id=130011792193300"
    },
}

local animMap = {
    idle  = { folder = "idle",  slots = { { child = "Animation1", origKey = "idle1" }, { child = "Animation2", origKey = "idle2" } } },
    walk  = { folder = "walk",  slots = { { child = "WalkAnim",   origKey = "walk"  } } },
    run   = { folder = "run",   slots = { { child = "RunAnim",    origKey = "run"   } } },
    jump  = { folder = "jump",  slots = { { child = "JumpAnim",   origKey = "jump"  } } },
    climb = { folder = "climb", slots = { { child = "ClimbAnim",  origKey = "climb" } } },
    fall  = { folder = "fall",  slots = { { child = "FallAnim",   origKey = "fall"  } } },
}

local allAnimOptions = {
    "Default", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost",
    "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon",
    "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar",
    "Princess", "Cowboy", "Patrol", "Zombie FE", "Catwalk Glam", "Amazon Unboxed",
    "Glow Motion", "Bubbly", "Adidas Comm", "KATSEYE", "Wicked Popular",
    "Dizzy", "WDTL", "Billie Eilish", "Cute Bouncy", "Cute",
    "Jolly", "Cute Kawaii", "Doll 3.0", "Victoria Model",
    "Bike/Bicyclist", "Animal", "It-Girl Essential Model",
    "Oldschool", "Spider", "Joy", "Flying Aura", "FHA V2", "Silent Nurse", "Supermodel", "Enchanted Fairy", "Furry", "Vlada Model", "R6 Converter"
}

local runAnimOptions = {
    "Default", "OG Rthro Run", "Vampire", "Hero", "Zombie Classic", "Mage", "Ghost",
    "Elder", "Levitation", "Astronaut", "Ninja", "Werewolf", "Cartoon",
    "Pirate", "Sneaky", "Toy", "Knight", "Confident", "Popstar",
    "Princess", "Cowboy", "Patrol", "Zombie FE", "Catwalk Glam", "Amazon Unboxed",
    "Glow Motion", "Bubbly", "Adidas Comm", "KATSEYE", "Wicked Popular",
    "Dizzy", "WDTL", "Billie Eilish", "Cute Bouncy", "Cute",
    "Jolly", "Cute Kawaii", "Doll 3.0", "Victoria Model",
    "Bike/Bicyclist", "Animal", "It-Girl Essential Model",
    "Oldschool", "Spider", "Joy", "Flying Aura", "FHA V2", "Silent Nurse", "Supermodel", "Enchanted Fairy", "Furry", "Vlada Model", "R6 Converter"
}


local allowed={}
for key in pairs(runtime.selections) do
    allowed[key]={}
    for _,name in ipairs(key=="run" and runAnimOptions or allAnimOptions) do allowed[key][name]=true end
end
local function LoadSettings()
    if not canPersist then
        WarnOnce("filesystem","readfile/writefile unavailable; settings are session-only.")
        return
    end
    if type(fileExists)=="function" then
        local ok,exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="function" then
            runtime.saveStatus="Read error"
            WarnOnce("read","Cannot read the settings file.")
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" or data.version~=1 or type(data.selections)~="table" then
        runtime.saveStatus="Invalid file"
        WarnOnce("read","Invalid settings file; kept unchanged until you edit a setting.")
        return
    end
    if type(data.enabled)=="boolean" then runtime.enabled=data.enabled end
    for key in pairs(runtime.selections) do
        local value=data.selections[key]
        if type(value)=="string" and allowed[key][value] then runtime.selections[key]=value end
    end
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,enabled=runtime.enabled,selections=runtime.selections}))
    end)
    if not ok then
        runtime.saveStatus="Write error"
        WarnOnce("write","Cannot save settings: "..tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="Saved"
    return true
end
LoadSettings()
local statusLabel
local function Status(text)
    runtime.status=text
    if statusLabel then pcall(function() statusLabel:SetValue(text) end) end
end
local changed={} -- [Animation instance] = {original=assetId,last=assetId,animate=LocalScript}
local touched={} -- Animate scripts refreshed by this plugin, including Default selections.
local restarts={} -- One pending restart per Animate; newest batch owns its restart.

-- AnimationTrack.Animation may reference the very Animation whose ID we replace.
-- Matching tracks by that ID AFTER writing IDs misses stale, still-playing tracks.
-- A full transition reset also clears cross-fading tracks and cached idle/run blends.
local function StopTracks(animate)
    local character=animate.Parent
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    local animator=humanoid:FindFirstChildOfClass("Animator")
    local ok,tracks=pcall(function()
        return animator and animator:GetPlayingAnimationTracks() or humanoid:GetPlayingAnimationTracks()
    end)
    if not ok then
        WarnOnce("tracks","Cannot enumerate active animation tracks: "..tostring(tracks))
        return false
    end
    local stopped=true
    for _,track in ipairs(tracks) do
        -- Do not destroy tracks owned by tools/emotes or other scripts. This reset
        -- interrupts them once, but does not permanently block future animations.
        pcall(function() track:AdjustWeight(0,0) end)
        local stopOK=pcall(function() track:Stop(0) end)
        if not stopOK then stopped=false end
    end
    if not stopped then WarnOnce("stop","Some animation tracks could not be stopped.") end
    return stopped
end
local function FinishRestart(animate,lease)
    if restarts[animate]~=lease then return true end -- superseded by a later toggle/choice
    local stopOK=StopTracks(animate)
    -- Always attempt to restore Disabled, even if stopping a track failed.
    local ok,err=pcall(function() animate.Disabled=lease.wasDisabled end)
    if ok then
        restarts[animate]=nil
    else
        WarnOnce("restart","Could not restart Animate: "..tostring(err))
    end
    return ok and stopOK
end
local function WriteBatch(animate,entries,forceRestart)
    if #entries==0 and not forceRestart then return true end
    local pending=restarts[animate]
    local wasDisabled=animate.Disabled
    if pending then wasDisabled=pending.wasDisabled end
    local lease={wasDisabled=wasDisabled}
    restarts[animate]=lease
    local stopped=true
    -- ID writes never yield. A new request cannot observe a half-written batch.
    local ok,err=pcall(function()
        animate.Disabled=true
        stopped=StopTracks(animate) -- BEFORE mutating Animation.AnimationId
        for _,entry in ipairs(entries) do
            entry.anim.AnimationId=entry.value
            if entry.saved and entry.anim.AnimationId==entry.value then entry.saved.beforeWrite=nil end
        end
    end)
    if not ok then
        FinishRestart(animate,lease)
        WarnOnce("apply","Animation update failed: "..tostring(err))
        return false
    end
    task.spawn(function()
        -- Keep Animate stopped for actual scheduler frames; an immediate true/false
        -- flip is not a reliable script restart. New requests inherit the ORIGINAL
        -- Disabled state, not the temporary true used by this transaction.
        task.wait(0.1)
        if restarts[animate]~=lease then return end
        local restarted=FinishRestart(animate,lease)
        if not restarted and runtime.alive then Status("Reset incomplete — press Reapply / Retry") end
    end)
    return stopped
end
local function RestoreOriginals()
    local batches={}
    local restored=true
    -- Even if IDs are already original, old loaded tracks may still be running.
    for animate in pairs(touched) do
        if animate.Parent then batches[animate]={} else touched[animate]=nil end
    end
    for anim,saved in pairs(changed) do
        local ok,current=pcall(function() return anim.Parent and anim.AnimationId end)
        if not ok or not current or not saved.animate.Parent then
            changed[anim]=nil
        elseif current==saved.original then
            changed[anim]=nil
        elseif current~=saved.last and (saved.beforeWrite==nil or current~=saved.beforeWrite) then
            WarnOnce("conflict","Another script changed an animation; its ID was left untouched.")
            changed[anim]=nil
        else
            batches[saved.animate]=batches[saved.animate] or {}
            table.insert(batches[saved.animate],{anim=anim,value=saved.original})
        end
    end
    for animate,entries in pairs(batches) do
        if WriteBatch(animate,entries,true) then touched[animate]=nil else restored=false end
        for _,entry in ipairs(entries) do
            if entry.anim.AnimationId==entry.value then changed[entry.anim]=nil else restored=false end
        end
    end
    return restored
end
local function Current(character,ticket)
    return runtime.alive and runtime.enabled and runtime.generation==ticket and LocalPlayer.Character==character
end
local function ReadySlots(character,ticket)
    local deadline=os.clock()+10
    repeat
        if not Current(character,ticket) then return nil,"Cancelled" end
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.RigType~=Enum.HumanoidRigType.R15 then
            return nil,"R15 required — settings retained"
        end
        if humanoid and humanoid.Health<=0 then return nil,"Waiting for respawn" end
        local animate=character:FindFirstChild("Animate")
        if humanoid and animate then
            local slots={}
            local complete=true
            for animType,info in pairs(animMap) do
                local folder=animate:FindFirstChild(info.folder)
                for _,slot in ipairs(info.slots) do
                    local anim=folder and folder:FindFirstChild(slot.child)
                    if not anim or not anim:IsA("Animation") or anim.AnimationId=="" then
                        complete=false
                    else
                        table.insert(slots,{anim=anim,kind=animType,key=slot.origKey})
                    end
                end
            end
            if complete then return {animate=animate,slots=slots} end
        end
        task.wait(0.1)
    until os.clock()>=deadline
    return nil,"Animate not ready — use Reapply / Retry"
end
local function ApplyReady(ready,forceRestart)
    local entries={}
    for _,slot in ipairs(ready.slots) do
        local anim=slot.anim
        local saved=changed[anim]
        -- If a game/avatar script replaced an ID since our last write, use that
        -- new ID as the restoration baseline rather than a stale avatar default.
        if saved and anim.AnimationId~=saved.last and anim.AnimationId~=saved.original and anim.AnimationId~=saved.beforeWrite then
            changed[anim]=nil
            saved=nil
        end
        local original=saved and saved.original or anim.AnimationId
        local name=runtime.selections[slot.kind]
        if name=="Default" then name=runtime.selections.all end
        local preset=animPresets[name]
        local desired=preset and preset[slot.key] or original
        if anim.AnimationId~=desired then
            saved=saved or {original=original,animate=ready.animate}
            -- Each batch is synchronous; a failed assignment leaves either the
            -- old value or this intended value, both safe for restoration.
            saved.beforeWrite=anim.AnimationId
            saved.last=desired
            changed[anim]=saved
            table.insert(entries,{anim=anim,value=desired,saved=saved})
        end
    end
    if #entries>0 or forceRestart then touched[ready.animate]=true end
    if not WriteBatch(ready.animate,entries,forceRestart) then return false end
    for _,entry in ipairs(entries) do
        if entry.anim.AnimationId~=entry.value then return false end
    end
    return true
end
local function RequestApply()
    runtime.generation=runtime.generation+1
    local ticket=runtime.generation
    if not runtime.alive then return end
    if not runtime.enabled then
        Status(RestoreOriginals() and "OFF — original animations restored" or "OFF — restoration pending; press Retry")
        return
    end
    local character=LocalPlayer.Character
    if not character then Status("Waiting for character"); return end
    Status("Applying saved selection...")
    task.spawn(function()
        local ok,err=pcall(function()
            local ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if not ready then Status(reason); return end
            if ApplyReady(ready,true) then Status("ON — selection applied") else Status("Could not apply — press Retry") end
            -- A single delayed recheck handles late avatar appearance updates.
            task.wait(0.5)
            if not Current(character,ticket) then return end
            ready,reason=ReadySlots(character,ticket)
            if not Current(character,ticket) then return end
            if ready then
                if ApplyReady(ready) then Status("ON — selection applied") else Status("Could not apply — press Retry") end
            else Status(reason) end
        end)
        if not ok and Current(character,ticket) then
            Status("Animation error — press Retry")
            WarnOnce("worker",tostring(err))
        end
    end)
end
runtime.Reapply=RequestApply
runtime.SaveSettings=SaveSettings
local characterConnection
local appearanceConnection
function runtime.Cleanup()
    runtime.alive=false
    runtime.generation=runtime.generation+1
    if characterConnection then characterConnection:Disconnect() end
    if appearanceConnection then appearanceConnection:Disconnect() end
    local restored=RestoreOriginals()
    -- Cleanup must leave no deferred restart that could interfere with a reload.
    local pending={}
    for animate,lease in pairs(restarts) do pending[#pending+1]={animate=animate,lease=lease} end
    for _,item in ipairs(pending) do
        if not FinishRestart(item.animate,item.lease) then restored=false end
    end
    return restored
end

local tab=shared.CreateTab("FE Animations","/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
local section=tab:AddSection("FE Animations","aux0on presets • R15 • full track reset • auto-save")
statusLabel=section:AddLabel("Loading settings...",true)
section:AddParagraph("Saved settings","Toggle and all animation choices are saved automatically. Individual Default uses All Animations; All Animations = Default uses your avatar's originals. R15 only.")
local toggle=section:AddToggle("Enable FE Anims",function(value)
    if runtime.initializing or not runtime.alive then return end
    runtime.enabled=value==true
    SaveSettings()
    RequestApply()
end)
local dropdowns={
    {label="All Animations",key="all"},
    {label="Idle Animation",key="idle"},
    {label="Walk Animation",key="walk"},
    {label="Run Animation",key="run"},
    {label="Jump Animation",key="jump"},
    {label="Climb Animation",key="climb"},
    {label="Fall Animation",key="fall"},
}
for _,dd in ipairs(dropdowns) do
    local key=dd.key
    local control=section:AddDropdown(dd.label,key=="run" and runAnimOptions or allAnimOptions,function(value)
        if runtime.initializing or not runtime.alive or type(value)~="string" or not allowed[key][value] then return end
        runtime.selections[key]=value
        SaveSettings()
        if runtime.enabled then RequestApply() end
    end)
    if control then
        local ok=pcall(function() control:Select(runtime.selections[key]) end)
        if not ok then WarnOnce("ui","Could not display a saved selection; the backing setting is retained.") end
    end
end
section:AddParagraph("Full animation reset","Switching presets, toggling OFF or pressing Retry briefly stops ALL current animation tracks, including emotes/tool poses, then restarts Animate. Nothing is blocked permanently.")
section:AddButton("Reapply / Retry",function() if runtime.alive then RequestApply() end end)
if runtime.enabled and type(toggle)=="function" then
    local ok=pcall(toggle)
    if not ok then WarnOnce("toggle","Could not display the saved toggle state.") end
end
runtime.initializing=false
_G[KEY]=runtime
characterConnection=LocalPlayer.CharacterAdded:Connect(function()
    if not runtime.alive then return end
    RestoreOriginals()
    RequestApply()
end)
appearanceConnection=LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
    if runtime.alive and runtime.enabled and character==LocalPlayer.Character then RequestApply() end
end)
RequestApply()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: Anims.lua.txt] " .. tostring(__pluginError))
            notify("Anims.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    -- ================================================================
    -- EMBEDDED PLUGIN: BJP.lua.txt
    do
        local __pluginOk, __pluginError = xpcall(function()
-- ODH 2026 adapter. Embedded in every plugin; no downloads/dependencies.
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "BJP", "Bomb Jump+", "ODH_BJP_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="function", X.title .. ": load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = game:GetService("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)
        if type(host.Notify)=="function" then pcall(host.Notify, X.title .. ": " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil -- never serialize Instances, connections, functions or players
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="function" and type(wr)=="function" then
            local present=true
            if type(exists)=="function" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then X.data=data
                    else X.badFile=true; report("Invalid settings file; defaults loaded. A manual change will replace it.") end
                elseif type(exists)=="function" then report("Could not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host}) -- never mutate the host API
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end
    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif type(wr)=="function" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        -- Options before enabling modules. Actions and player selections are never replayed.
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Commit() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"/mellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys") -- key-capture toggles are actions, not enabled modes
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("Dropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb) return raw:AddPlayerDropdown(label,action(cb)) end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(...) return raw:AddParagraph(...) end
        return section
    end
    -- Stable GUI paths, never serialized Instances. Player name is session-independent.
    function X.Path(object)
        local parts={}
        local player=game:GetService("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=game:GetService("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Commit()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        if X.cleanup then pcall(X.cleanup) end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()
-- END ODH 2026 ADAPTER

local table_insert = table.insert

local Maid = {}
Maid.__index = Maid

function Maid.new() 
    return setmetatable({_tasks = {}, _destroyed = false}, Maid) 
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy() 
    self:DoCleaning() 
end

local RootMaid = Maid.new()

local shared = ODHX.shared

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    SoundService = game:GetService("SoundService")
}

local LocalPlayer = Services.Players.LocalPlayer

local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local BBSystem = {Buttons = {}, Connections = {}}

local function bb_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BB ERROR] " .. tostring(err)) end
end

local function BB_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@odh_bjp_bigstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@odh_bjp_bigstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local __BB_GRAD_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    __PCLR(0.0784314, 0.0784314, 0.0784314)),
    ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
    ColorSequenceKeypoint.new(1,    __PCLR(0.470588,  0.156863,  0.470588))
})

local function BB_MakeDraggable(gui, func, ripple, sound)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local normalSize    = __UD2(0, 200, 0, 75)
    local normalTxtSize = 24
    local bigSize       = __UD2(0, 220, 0, 82.5)
    local bigTxtSize    = 26.4

    ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            hasMoved  = false
            dragStart = input.Position
            startPos  = gui.Position
            __TS:Create(gui, tInfo, {Size = bigSize, TextSize = bigTxtSize}):Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            sound:Play()
            __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 300, 0, 300),
                BackgroundTransparency = 1
            }):Play()
            local rel
            rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    __TS:Create(gui, tInfo, {Size = normalSize, TextSize = normalTxtSize}):Play()
                    if not hasMoved then bb_safecallback(func) end
                    rel:Disconnect()
                end
            end)
        end
    end)
    ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    ODHX.Connect(__UIS.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local BindableButtons
local muteButtonSounds = false

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in pairs(BBSystem.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

local function AddBigButton(id, text, func, isGold, customSize)
    if BBSystem.Buttons[id] then return end
    local storage = BB_GetStorage()
    local bb = Instance.new("TextButton")
    bb.Name = id
    bb.Size = customSize or __UD2(0, 200, 0, 75)
    bb.Position = __UD2(0.5, 0, 0.5, 0)
    bb.AnchorPoint = __V2(0.5, 0.5)
    bb.BackgroundColor3 = __RGB(255, 255, 255)
    bb.BackgroundTransparency = 0.9
    bb.BorderSizePixel = 0
    bb.Font = Enum.Font.Jura
    bb.Text = text
    bb.TextSize = 24
    bb.TextColor3 = __RGB(255, 255, 255)
    bb.TextWrapped = true
    bb.ClipsDescendants = true
    bb.AutoButtonColor = false
    bb.ZIndex = 5
    bb.Parent = storage

    Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
    local stroke = Instance.new("UIStroke")
    stroke.Color = __RGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bb
    local gradient = Instance.new("UIGradient")
    
    if isGold then
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    __RGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5,  __RGB(255, 140, 0)),
            ColorSequenceKeypoint.new(1,    __RGB(184, 134, 11))
        })
    else
        gradient.Color = __BB_GRAD_SEQ
    end
    gradient.Parent = stroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.ZIndex = 4
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.Parent = bb
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = bb

    BB_MakeDraggable(bb, func, ripple, sound)
    BBSystem.Connections[id] = ODHX.Connect(__RS.RenderStepped, function()
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end)
    BBSystem.Buttons[id] = bb
    return bb
end

local function DeleteBigButton(id)
    if BBSystem.Buttons[id] then
        if BBSystem.Connections[id] then
            BBSystem.Connections[id]:Disconnect()
            BBSystem.Connections[id] = nil
        end
        BBSystem.Buttons[id]:Destroy()
        BBSystem.Buttons[id] = nil
    end
end

BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local __WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.827451, 0.133333, 0.133333)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local __GOLD_NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __RGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(255, 140, 0)),
    ColorSequenceKeypoint.new(1,   __RGB(184, 134, 11))
})

local __GOLD_WAIT_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __RGB(255, 69, 0)),
    ColorSequenceKeypoint.new(0.6, __RGB(139, 69, 19)),
    ColorSequenceKeypoint.new(1,   __RGB(160, 82, 45))
})

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@odh_bjp_bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@odh_bjp_bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    
    maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    rel:Disconnect()
                end
            end)
        end
    end))
    
    maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    
    maid:GiveTask(ODHX.Connect(__UIS.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function BindableButtons.AddBButton(id, text, clickFunc, isGold, customSize)
    if BindableButtons.Buttons[id] then return end
    
    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = customSize or 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = __RGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.28
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("UICorner", ImageButton).CornerRadius = __UD(0, 1000)
    local outerButtonStroke = Instance.new("UIStroke", ImageButton)
    outerButtonStroke.Color = __PCLR(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("UIStroke", ImageButton)
    innerButtonStroke.Color = __RGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 14
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", outerButtonStroke)
    Stroke.Name = "@Stroke"
    Stroke.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, __RGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, __RGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, __RGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, __RGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, __RGB(45, 45, 52)),
    })
    local innerButtonGradient = Stroke:Clone()
    innerButtonGradient.Rotation = 180
    innerButtonGradient.Parent = innerButtonStroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    buttonMaid:GiveTask(ODHX.Connect(__RS.RenderStepped, function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
    local btn = BindableButtons.Buttons[id]
    if not btn then return end
    
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then
        textLabel.Text = text
    end
    
    local stroke = btn:FindFirstChild("@Stroke")
    if stroke then
        if isGold then
            stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
        else
            stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
        end
    end
end

local function GetSafeGuiRoot()
    local success, result = pcall(function() 
        return gethui() 
    end)
    if success and result and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local _game = shared.game_name
if not _game and (game.PlaceId == 142823291 or game.GameId == 66654135) then _game = "Murder Mystery 2" end

if _game == "Murder Mystery 2" or _game == "Murder Mystery Modded" then

local aboutSection = shared.AddSection("About")

aboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

shared.Notify("Bomb Jump+ Successfully Loaded", 5)

-- ============================================
-- УЛУЧШЕННАЯ СИСТЕМА ДЛЯ РАБОТЫ С БОМБАМИ
-- ============================================

local CONFIG = {
    CooldownTime = 22.0,
    LaunchPower = 58,
    MinSize = 50,
    MaxSize = 300,
    DefaultSize = 90,
    BindDefaultSize = 0.11
}

-- Расширенный список имен бомб для MM2
local BOMB_NAMES = {
    "FakeBomb", 
    "Bomb", 
    "GiftBomb", 
    "PresentBomb",
    "Snowball",  -- Для зимних событий
    "CandyBomb"  -- Для хэллоуинских событий
}

-- Конфигурация для разных типов бомб
local BOMB_CONFIGS = {
    FakeBomb = {
        Cooldown = 22,
        Power = 58,
        IsGold = false,
        RemotePath = "Remote",
        DisplayName = "Bomb Jump"
    },
    GoldBomb = {
        Cooldown = 4,
        Power = 65,
        IsGold = true,
        RemotePath = "Remote",
        DisplayName = "Gold Bomb Jump"
    }
}

-- ============================================
-- УНИВЕРСАЛЬНАЯ СИСТЕМА BOMB JUMP
-- ============================================

local function CreateBombJumpSystem(config)
    -- config = {
    --     bombType = "FakeBomb" или "GoldBomb",
    --     section = shared.AddSection(...),
    --     defaultEnabled = false,
    --     defaultAutoGet = false,
    --     defaultBigButton = false,
    --     defaultBindButton = false,
    --     bigButtonSize = 200,
    --     bindButtonSize = 0.11,
    --     keybind = "E"
    -- }
    
    local bombConfig = BOMB_CONFIGS[config.bombType]
    if not bombConfig then return nil end
    
    local isGold = bombConfig.IsGold
    local bombName = config.bombType
    local cooldownTime = bombConfig.Cooldown
    local launchPower = bombConfig.Power
    local displayName = config.displayName or bombConfig.DisplayName
    
    -- Состояние системы
    local state = {
        enabled = false,
        onCooldown = false,
        debounce = false,
        autoGetBomb = false,
        justRespawned = false,
        bigButtonSize = config.bigButtonSize or 200,
        bindButtonSize = config.bindButtonSize or 0.11,
        bigBtnExists = false,
        bindBtnExists = false,
        bindButton = nil,
        activeTouches = {}
    }
    
    -- Maid для очистки
    local systemMaid = Maid.new()
    RootMaid:GiveTask(systemMaid)
    
    -- Звуки
    local Sounds = {
        Click = Instance.new("Sound"),
        Cooldown = Instance.new("Sound")
    }
    Sounds.Click.SoundId = "rbxassetid://6895079853"
    Sounds.Click.Volume = 1.0
    Sounds.Cooldown.SoundId = "rbxassetid://138090596"
    Sounds.Cooldown.Volume = 1.0
    
    local function PlaySound(snd)
        pcall(function()
            if snd then
                Services.SoundService:PlayLocalSound(snd)
            end
        end)
    end
    
    -- Вспомогательные функции
    local function IsPlayerInAir()
        local character = LocalPlayer.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return false end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or 
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.Freefall then
            return true
        end
        
        local velocityY = rootPart.Velocity.Y
        return math.abs(velocityY) > 0.5
    end
    
    local function ResetCooldown()
        state.onCooldown = false
        local bigBtn = BBSystem.Buttons[config.bigButtonId]
        if bigBtn then bigBtn.Text = displayName end
        if state.bindButton then
            BindableButtons.UpdateBButtonText(config.bindButtonId, 
                isGold and "GBJ" or "BJ", false, isGold)
        end
    end
    
    local function StartCooldown()
        state.onCooldown = true
        state.debounce = false
        local bigBtn = BBSystem.Buttons[config.bigButtonId]
        if bigBtn then bigBtn.Text = "Wait" end
        if state.bindButton then
            BindableButtons.UpdateBButtonText(config.bindButtonId, 
                "Wait", true, isGold)
        end
        
        task.spawn(function()
            for i = cooldownTime, 1, -1 do
                if not state.onCooldown then break end
                local bigBtn = BBSystem.Buttons[config.bigButtonId]
                if bigBtn then bigBtn.Text = tostring(i) end
                if state.bindButton then
                    BindableButtons.UpdateBButtonText(config.bindButtonId, 
                        tostring(i), true, isGold)
                end
                task.wait(1)
            end
            if state.onCooldown then ResetCooldown() end
        end)
    end
    
    local function GetCenterPosition()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            -- Кидаем бомбу под ноги для максимальной эффективности
            local lookDir = Services.Workspace.CurrentCamera.CFrame.LookVector
            return root.Position + (lookDir * 3) + Vector3.new(0, -2, 0)
        end
        return nil
    end
    
    local function MakeCharacterJump()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    
    local function UnequipBomb(bombName)
        task.spawn(function()
            task.wait(0.5)
            local character = LocalPlayer.Character
            if character then
                local bomb = character:FindFirstChild(bombName)
                if bomb then
                    bomb.Parent = LocalPlayer.Backpack or character
                end
            end
        end)
    end
    
    local function GetAnyBomb(bombName)
        local character = LocalPlayer.Character
        if not character then return false, nil end
        
        -- Проверяем все возможные имена бомб
        local bombNamesToCheck = {bombName}
        if bombName == "FakeBomb" then
            -- Для обычной бомбы проверяем все возможные имена
            bombNamesToCheck = BOMB_NAMES
        end
        
        for _, name in ipairs(bombNamesToCheck) do
            local bomb = character:FindFirstChild(name)
            if bomb then return true, bomb end
        end
        
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, name in ipairs(bombNamesToCheck) do
                local bomb = backpack:FindFirstChild(name)
                if bomb then
                    bomb.Parent = character
                    return true, bomb
                end
            end
        end
        
        -- Пытаемся получить бомбу через Remote с таймаутом
        local success = false
        local attempts = 0
        while not success and attempts < 3 do
            attempts = attempts + 1
            local ok = pcall(function()
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
            end)
            if ok then 
                success = true
                break
            end
            task.wait(0.1)
        end
        
        if success then
            for _ = 1, 5 do
                for _, name in ipairs(bombNamesToCheck) do
                    local bomb = character:FindFirstChild(name)
                    if bomb then return true, bomb end
                    if backpack then
                        bomb = backpack:FindFirstChild(name)
                        if bomb then
                            bomb.Parent = character
                            return true, bomb
                        end
                    end
                end
                task.wait(0.05)
            end
        end
        
        return false, nil
    end
    
    local function IsHoldingBomb(bombName)
        local character = LocalPlayer.Character
        if not character then return false end
        
        local bombNamesToCheck = {bombName}
        if bombName == "FakeBomb" then
            bombNamesToCheck = BOMB_NAMES
        end
        
        for _, name in ipairs(bombNamesToCheck) do
            if character:FindFirstChild(name) then
                return true
            end
        end
        return false
    end
    
    -- Основная функция прыжка
    local function FastBombJump()
        if not IsPlayerInAir() then return end
        if state.onCooldown or state.debounce or state.justRespawned then return end
        state.debounce = true
        
        local success, bomb = GetAnyBomb(bombName)
        
        if success and bomb then
            local position = GetCenterPosition()
            if position then
                local remote = bomb:FindFirstChild("Remote")
                if remote then
                    PlaySound(Sounds.Click)
                    pcall(function()
                        remote:FireServer(CFrame.new(position), 50)
                    end)
                end
                
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local currentVelocity = root.AssemblyLinearVelocity
                    -- Добавляем к текущей скорости, а не заменяем
                    root.AssemblyLinearVelocity = Vector3.new(
                        currentVelocity.X, 
                        currentVelocity.Y + launchPower, 
                        currentVelocity.Z
                    )
                end
                
                MakeCharacterJump()
                UnequipBomb(bomb.Name)
                
                task.spawn(function()
                    task.wait(0.1)
                    StartCooldown()
                end)
            end
        end
        
        task.spawn(function()
            task.wait(0.5)
            state.debounce = false
        end)
    end
    
    -- Настройка UI
    local section = config.section
    
    section:AddLabel(displayName .. " Options")
    section:AddToggle("Enable Auto " .. displayName, function(bool) 
        state.enabled = bool 
    end)
    
    section:AddToggle("Auto-Get " .. bombName, function(bool)
        state.autoGetBomb = bool
        if bool then
            pcall(function() 
                Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName) 
            end)
        end
    end)
    
    section:AddToggle("Enable " .. displayName .. " Bind Button", function(e)
        state.bindBtnExists = e
        if e then
            local shortName = isGold and "GBJ" or "BJ"
            BindableButtons.AddBButton(config.bindButtonId, shortName, FastBombJump, isGold, state.bindButtonSize)
            state.bindButton = BindableButtons.Buttons[config.bindButtonId]
            if state.bindButton then
                local screen = Services.Workspace.CurrentCamera.ViewportSize
                state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
                BindableButtons.UpdateBButtonText(config.bindButtonId, 
                    state.onCooldown and "Wait" or shortName, state.onCooldown, isGold)
            end
        else
            BindableButtons.DeleteBButton(config.bindButtonId)
            state.bindButton = nil
        end
    end)
    
    section:AddSlider(displayName .. " Bind Button Size", 5, 25, state.bindButtonSize * 100, function(value)
        state.bindButtonSize = value / 100
        if state.bindButton then
            local screen = Services.Workspace.CurrentCamera.ViewportSize
            state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
        end
    end)
    
    section:AddKeybind(displayName .. " Keybind", config.keybind, FastBombJump)
    
    -- Обработка ввода
    local TAP_MOVEMENT_THRESHOLD = 10
    local TAP_TIME_THRESHOLD = 0.3
    
    systemMaid:GiveTasks(
        ODHX.Connect(Services.UserInputService.InputBegan, function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Touch or 
               input.UserInputType == Enum.UserInputType.MouseButton1 then
                state.activeTouches[input] = {
                    startPosition = input.Position, 
                    startTime = tick(), 
                    moved = false
                }
            end
        end),
        ODHX.Connect(Services.UserInputService.InputChanged, function(input)
            local data = state.activeTouches[input]
            if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then
                data.moved = true
            end
        end),
        ODHX.Connect(Services.UserInputService.InputEnded, function(input, gp)
            if gp then 
                state.activeTouches[input] = nil 
                return 
            end
            local data = state.activeTouches[input]
            if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
                if state.enabled and not state.onCooldown and not state.debounce then
                    if IsHoldingBomb(bombName) and IsPlayerInAir() then
                        FastBombJump()
                    end
                end
            end
            state.activeTouches[input] = nil
        end),
        ODHX.Connect(LocalPlayer.CharacterAdded, function()
            ResetCooldown()
            state.activeTouches = {}
            state.justRespawned = true
            task.wait(1)
            state.justRespawned = false
            if state.autoGetBomb then
                task.wait(0.2)
                pcall(function() 
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName) 
                end)
            end
        end)
    )
    
    ODHX.Bind(section.Name, "Enable Auto " .. displayName, "Toggle", function() return state.enabled end)
    ODHX.Bind(section.Name, "Auto-Get " .. bombName, "Toggle", function() return state.autoGetBomb end)
    ODHX.Bind(section.Name, "Enable " .. displayName .. " Bind Button", "Toggle", function() return state.bindBtnExists end)
    ODHX.Bind(section.Name, displayName .. " Bind Button Size", "Slider", function() return state.bindButtonSize * 100 end)
    -- Возвращаем управление
    return {
        GetState = function() return state end,
        FastBombJump = FastBombJump,
        ResetCooldown = ResetCooldown,
        SetEnabled = function(bool) state.enabled = bool end,
        SetAutoGet = function(bool) 
            state.autoGetBomb = bool
            if bool then
                pcall(function() 
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName) 
                end)
            end
        end
    }
end

-- ============================================
-- СОЗДАНИЕ СИСТЕМ
-- ============================================

local section = shared.AddSection("Bomb Jump+")

-- Обычная бомба
local bombJumpSystem = CreateBombJumpSystem({
    bombType = "FakeBomb",
    section = section,
    displayName = "Bomb Jump",
    defaultEnabled = false,
    defaultAutoGet = false,
    defaultBigButton = false,
    defaultBindButton = false,
    bigButtonSize = 90,
    bindButtonSize = 0.11,
    keybind = "E",
    bigButtonId = "bombjump_big",
    bindButtonId = "bombjump_bind"
})

-- Золотая бомба (только для модов)
if _game == "Murder Mystery Modded" then
    local gbjSection = shared.AddSection("Gold Bomb Jump+")
    
    local goldBombJumpSystem = CreateBombJumpSystem({
        bombType = "GoldBomb",
        section = gbjSection,
        displayName = "Gold Bomb Jump",
        defaultEnabled = false,
        defaultAutoGet = false,
        defaultBigButton = false,
        defaultBindButton = false,
        bigButtonSize = 200,
        bindButtonSize = 0.11,
        keybind = "G",
        bigButtonId = "goldbombjump_big",
        bindButtonId = "goldbombjump_bind"
    })
end

ODHX.Bind("About", "Mute Button SFX", "Toggle", function() return muteButtonSounds end)

end

ODHX.cleanup=function()
    RootMaid:DoCleaning()
    for id in pairs(BBSystem.Buttons) do DeleteBigButton(id) end
    for id in pairs(BindableButtons.Buttons) do BindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: BJP.lua.txt] " .. tostring(__pluginError))
            notify("BJP.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    -- ================================================================
    -- EMBEDDED PLUGIN: unlimit.lua.txt
    do
        local __pluginOk, __pluginError = xpcall(function()
-- Inventory Unlimiter V5: current ODH plugin API + durable preferences.
-- Changes CLIENT-side values only; server-side limits are not bypassed by this file.
local shared = odh_shared_plugins
if not shared or type(shared.CreateTab) ~= "function" then
    warn("[Inventory Unlimiter] Load through the current Overdrive H plugin menu.")
    return
end

local KEY = "ODH_InventoryUnlimiterRuntime"
local previous = _G[KEY]
if type(previous) == "table" and type(previous.Cleanup) == "function" then
    local ok, restored = pcall(previous.Cleanup)
    if not ok or restored == false then
        warn("[Inventory Unlimiter] Could not restore the previous instance; reload cancelled.")
        return
    end
end

local runtime = { alive=true, initializing=true, values={enabled=false, maxItems=9999}, generation=0 }
local warnings = {}
local function Notify(text, duration)
    if type(shared.Notify) == "function" then pcall(shared.Notify, text, duration or 3) end
end
local function WarnOnce(key, text)
    if warnings[key] then return end
    warnings[key] = true
    warn("[Inventory Unlimiter] " .. text)
    Notify("Inventory Unlimiter: " .. text, 5)
end
local function Finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end
local function ClampItems(value)
    if not Finite(value) then return nil end
    return math.clamp(math.floor(value+0.5),2,9999)
end

-- File APIs are executor-provided, not part of odh_shared_plugins.
local environment = {}
if type(getgenv)=="function" then
    local ok, result=pcall(getgenv)
    if ok and type(result)=="table" then environment=result end
end
local fileRead = type(readfile)=="function" and readfile or environment.readfile
local fileWrite = type(writefile)=="function" and writefile or environment.writefile
local fileExists = type(isfile)=="function" and isfile or environment.isfile
local FILE = "ODH_InventoryUnlimiter_settings.json"
local httpOK, HttpService = pcall(function() return game:GetService("HttpService") end)
local canPersist = type(fileRead)=="function" and type(fileWrite)=="function" and httpOK and HttpService~=nil
runtime.settingsFile=FILE
runtime.saveStatus="Not saved"

local function LoadSettings()
    if not canPersist then
        runtime.saveStatus="Unavailable"
        WarnOnce("filesystem","readfile/writefile unavailable; settings cannot survive rejoining.")
        return
    end
    if type(fileExists)=="function" then
        local ok, exists=pcall(fileExists,FILE)
        if ok and not exists then return end
    end
    local ok,text=pcall(fileRead,FILE)
    if not ok then
        if type(fileExists)=="function" then
            runtime.saveStatus="Read error"
            WarnOnce("read","Cannot read settings: " .. tostring(text))
        end
        return
    end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" or data.version~=1 or type(data.values)~="table" then
        runtime.saveStatus="Invalid file"
        WarnOnce("read","Invalid settings file. Kept unchanged until you change a setting.")
        return
    end
    if type(data.values.enabled)=="boolean" then runtime.values.enabled=data.values.enabled end
    runtime.values.maxItems=ClampItems(data.values.maxItems) or 9999
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if not runtime.alive or runtime.initializing or not canPersist then return false end
    local ok,err=pcall(function()
        fileWrite(FILE,HttpService:JSONEncode({version=1,values={
            enabled=runtime.values.enabled,maxItems=runtime.values.maxItems,
        }}))
    end)
    if not ok then
        runtime.saveStatus="Write error"
        WarnOnce("write","Cannot save settings: " .. tostring(err))
        return false
    end
    warnings.write=nil
    runtime.saveStatus="Saved"
    return true
end
LoadSettings()

-- The original plugin's target heuristics are retained. No globals are patched.
local debugLibrary = type(debug)=="table" and debug or {}
local function Resolve(primary, fallback, external)
    if type(primary)=="function" then return primary end
    if type(fallback)=="function" then return fallback end
    if type(external)=="function" then return external end
end
local getGC = Resolve(getgc, environment.getgc)
local readUpvalues = Resolve(debugLibrary.getupvalues, getupvalues, environment.getupvalues)
local writeUpvalue = Resolve(debugLibrary.setupvalue, setupvalue, environment.setupvalue)
local readInfo = Resolve(debugLibrary.getinfo, getinfo, environment.getinfo)
local readConstants = Resolve(debugLibrary.getconstants, getconstants, environment.getconstants)
local readName = Resolve(debugLibrary.info)

local changed = {} -- [function][numeric upvalue index] = {original=..., last=...}
local connection
local statusLabel
local function Status(text)
    runtime.status=text
    if statusLabel then pcall(function() statusLabel:SetValue(text) end) end
end
local function IsTarget(fn)
    local name
    if readInfo then
        local ok,info=pcall(readInfo,fn)
        if ok and type(info)=="table" then name=info.name end
    elseif readName then
        local ok,value=pcall(readName,fn,"n")
        if ok then name=value end
    end
    if name=="updateItemFrame" or name=="onItemEquipped" then return true end
    if readConstants then
        local ok,constants=pcall(readConstants,fn)
        if ok and type(constants)=="table" then
            local touch,equip=false,false
            for _,value in pairs(constants) do
                if value=="TouchBinding" then touch=true end
                if value=="EquipButton" then equip=true end
            end
            return touch and equip
        end
    end
    return false
end
local function WriteAndVerify(fn,index,value)
    local ok,err=pcall(writeUpvalue,fn,index,value)
    if not ok then return false,tostring(err) end
    local readable,values=pcall(readUpvalues,fn)
    if not readable or type(values)~="table" or values[index]~=value then
        return false,"upvalue verification failed"
    end
    return true
end
local function RestoreOriginals()
    local allRestored=true
    for fn,slots in pairs(changed) do
        local readable,values=pcall(readUpvalues,fn)
        if not readable or type(values)~="table" then
            allRestored=false
            WarnOnce("restore-read","Could not inspect previously changed values; restoration is pending.")
        else
            for index,saved in pairs(slots) do
                local current=values[index]
                if current==saved.original then
                    slots[index]=nil
                elseif current~=saved.last then
                    -- Another script/game update owns the current value. Do not overwrite it.
                    WarnOnce("conflict","A value changed elsewhere; left it untouched.")
                    slots[index]=nil
                else
                    local ok,err=WriteAndVerify(fn,index,saved.original)
                    if ok then slots[index]=nil
                    else
                        allRestored=false
                        WarnOnce("restore-write","Cannot restore an original limit: " .. tostring(err))
                    end
                end
            end
        end
        if next(slots)==nil then changed[fn]=nil end
    end
    return allRestored
end
local function ApplyLimit()
    if not (getGC and readUpvalues and writeUpvalue and (readInfo or readName or readConstants)) then
        Status("UNSUPPORTED: required executor debug functions are missing")
        WarnOnce("debug","Required debug functions are unavailable (getgc/getupvalues/setupvalue and target identification).")
        return 0
    end
    local ok,objects=pcall(getGC)
    if not ok or type(objects)~="table" then
        Status("ERROR: getgc failed")
        WarnOnce("scan","getgc failed: " .. tostring(objects))
        return 0
    end
    local target=runtime.values.maxItems
    local count=0
    for _,fn in pairs(objects) do
        if type(fn)=="function" and (changed[fn] or IsTarget(fn)) then
            local readable,values=pcall(readUpvalues,fn)
            if readable and type(values)=="table" then
                for index,value in pairs(values) do
                    if type(index)=="number" and index>=1 and index%1==0 and type(value)=="number" then
                        local slots=changed[fn]
                        local saved=slots and slots[index]
                        -- Existing tracked values remain targets after any Max Items change.
                        if saved or value==10 or value==3 then
                            if not saved then
                                slots=slots or {};changed[fn]=slots
                                saved={original=value,last=value};slots[index]=saved
                            end
                            if value==target then
                                saved.last=target;count=count+1
                            elseif value==saved.last or value==saved.original then
                                -- Record intent before writing, so cleanup can recover even
                                -- if the executor writes but verification subsequently fails.
                                saved.last=target
                                local applied,err=WriteAndVerify(fn,index,target)
                                if applied then count=count+1
                                else WarnOnce("apply","Cannot write/verify a target limit: " .. tostring(err)) end
                            else
                                WarnOnce("conflict","A value changed elsewhere; left it untouched.")
                            end
                        end
                    end
                end
            end
        end
    end
    if count>0 then Status("ON | Max Items: " .. target .. " | verified values: " .. count)
    else Status("WAITING | Inventory functions not found or not writable") end
    return count
end
local function RequestApply()
    runtime.generation=runtime.generation+1
    local token=runtime.generation
    if not runtime.values.enabled then
        local restored=RestoreOriginals()
        Status(restored and "OFF | Original values restored" or "OFF | Restoration pending; press Reapply / Retry")
        return
    end
    Status("Applying saved/current limit...")
    -- Bounded retries, not a continuous getgc loop. Old requests are cancelled
    -- by any new setting change, disable, reload, or respawn.
    task.spawn(function()
        for _,delay in ipairs({0.2,0.8,2.0}) do
            task.wait(delay)
            if not runtime.alive or runtime.generation~=token or not runtime.values.enabled then return end
            ApplyLimit()
        end
    end)
end
runtime.Cleanup=function()
    runtime.alive=false
    runtime.generation=runtime.generation+1
    if connection then connection:Disconnect();connection=nil end
    return RestoreOriginals() -- do not persist OFF merely because the runtime is unloading
end
runtime.SaveSettings=SaveSettings

-- UI: CreateTab uses a GitHub path without domain and without .png.
local UI_VERSION=5
local ui
if type(previous)=="table" and type(previous.ui)=="table"
    and previous.ui.owner==shared and previous.ui.version==UI_VERSION and previous.ui.complete then
    ui=previous.ui
else
    local ok,result=pcall(function()
        local tab=shared.CreateTab("Inventory Unlimiter", "/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
        return {owner=shared,version=UI_VERSION,tab=tab,
            section=tab:AddSection("Inventory Unlimiter V5","Client-side limit • Saved preferences"),visual=false}
    end)
    if not ok then warn("[Inventory Unlimiter] UI failed: " .. tostring(result));return end
    ui=result
end
runtime.ui=ui
ui.runtime=runtime
_G[KEY]=runtime
runtime.SetEnabled=function(state)
    runtime.values.enabled=state==true
    SaveSettings()
    RequestApply()
end
runtime.SetMaxItems=function(value)
    local number=ClampItems(value)
    if not number then return end
    runtime.values.maxItems=number
    SaveSettings()
    if runtime.values.enabled then RequestApply() end
end
runtime.Reapply=RequestApply

if not ui.complete then
    local ok,err=pcall(function()
        ui.section:AddParagraph("Persistence", "Toggle and Max Items are saved on change. Load this plugin again after joining; saved preferences restore automatically.")
        ui.toggle=ui.section:AddToggle("Unlimit Inventory",function(value)
            ui.visual=value==true
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetEnabled(value) end
        end)
        assert(type(ui.toggle)=="function","AddToggle must return a closure")
        ui.slider=ui.section:AddSlider("Max Items",2,9999,runtime.values.maxItems,function(value)
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.SetMaxItems(value) end
        end)
        ui.status=ui.section:AddLabel("Initializing...",true)
        ui.section:AddButton("Reapply / Retry",function()
            local active=ui.runtime
            if active and active.alive and not active.initializing then active.Reapply() end
        end)
    end)
    if not ok then runtime.Cleanup();warn("[Inventory Unlimiter] UI controls failed: " .. tostring(err));return end
    ui.complete=true
end
statusLabel=ui.status
local synced,err=pcall(function()
    ui.slider:SetValue(runtime.values.maxItems)
    if ui.visual~=runtime.values.enabled then ui.toggle() end
    assert(ui.visual==runtime.values.enabled,"toggle state mismatch")
end)
if not synced then runtime.Cleanup();warn("[Inventory Unlimiter] UI sync failed: " .. tostring(err));return end
runtime.initializing=false

local LocalPlayer=game:GetService("Players").LocalPlayer
if LocalPlayer then
    connection=LocalPlayer.CharacterAdded:Connect(function()
        if runtime.alive and runtime.values.enabled then RequestApply() end
    end)
end
RequestApply()
print("[Inventory Unlimiter V5] Loaded | Settings: " .. FILE .. " | " .. runtime.saveStatus)

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: unlimit.lua.txt] " .. tostring(__pluginError))
            notify("unlimit.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
    -- ================================================================
    -- EMBEDDED PLUGIN: Pm-Wallhop.lua.txt
    do
        local __pluginOk, __pluginError = xpcall(function()
-- ODH 2026 adapter. Embedded in every plugin; no downloads/dependencies.
local ODHX = (function()
    local X = { ready=false, silent=false, restoring=false, replay=true, records={}, byKey={}, data={version=1, controls={}}, external=false }
    X.id, X.title, X.file = "Pm-Wallhop", "Pm-WallHop", "ODH_Pm-Wallhop_settings.json"
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="function", X.title .. ": load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = game:GetService("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)
        if type(host.Notify)=="function" then pcall(host.Notify, X.title .. ": " .. message, 5) end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil -- never serialize Instances, connections, functions or players
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if type(rd)=="function" and type(wr)=="function" then
            local present=true
            if type(exists)=="function" then local ok,v=pcall(exists,X.file); if ok then present=v end end
            if present then
                local ok,text=pcall(rd,X.file)
                if ok then
                    local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                    if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then X.data=data
                    else X.badFile=true; report("Invalid settings file; defaults loaded. A manual change will replace it.") end
                elseif type(exists)=="function" then report("Could not read settings file: " .. tostring(text)); X.badFile=true end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host}) -- never mutate the host API
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end
    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif type(wr)=="function" then
                wr(X.file,http:JSONEncode(encode(X.data)))
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    function X.Restore()
        X.restoring=true
        -- Options before enabling modules. Actions and player selections are never replayed.
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Commit() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=host.CreateTab(X.title,"/mellnikovden968-web/CFG_PM2/refs/heads/main/icon") end
        local raw=tab:AddSection(name,subtitle or "")
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="🔑 Keys") -- key-capture toggles are actions, not enabled modes
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
            elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
            elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
            elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb) return register("Dropdown",label,cb,items[1],nil,nil,items) end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb) return raw:AddPlayerDropdown(label,action(cb)) end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(...) return raw:AddParagraph(...) end
        return section
    end
    -- Stable GUI paths, never serialized Instances. Player name is session-independent.
    function X.Path(object)
        local parts={}
        local player=game:GetService("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=game:GetService("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Commit()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        if X.cleanup then pcall(X.cleanup) end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end)()
-- END ODH 2026 ADAPTER

local shared = ODHX.shared
local UpdateWallhopButtonState, performVideoFlick, performWallhop

-- Создаем секцию для нашего плагина
local wallhop_section = shared.AddSection("Pm-WallHop")

-- Добавляем информацию
wallhop_section:AddLabel("Pm-WallHop Script by @Phemtom (Improved)")
wallhop_section:AddParagraph("Pm-WallHop", "Флинг при прыжке возле стыка стен")

-- Основной переключатель (ТОГГЛ)
local isWallHopEnabled = false
wallhop_section:AddToggle("Включить WallHop", function(bool)
    isWallHopEnabled = bool
    if bool then
        shared.Notify("Pm-WallHop включен", 2)
    else
        shared.Notify("Pm-WallHop выключен", 2)
    end
    UpdateWallhopButtonState()
end)

-- Кнопка ВКЛ/ВЫКЛ (дополнительная)
wallhop_section:AddButton("Вкл/Выкл WallHop", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "Pm-WallHop включен" or "Pm-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

-- Настройка чувствительности (дистанция обнаружения стены)
local detectionDistance = 3
wallhop_section:AddSlider("Дистанция обнаружения", 1, 6, 3, function(int)
    detectionDistance = int
    shared.Notify("Дистанция: " .. int, 2)
end)

-- Настройка силы флинга
local flickPower = 50
wallhop_section:AddSlider("Сила флинга", 20, 100, 50, function(int)
    flickPower = int
    shared.Notify("Сила: " .. int, 2)
end)

-- Клавиша для быстрого включения/выключения
wallhop_section:AddKeybind("Toggle Keybind", "F", function()
    isWallHopEnabled = not isWallHopEnabled
    shared.Notify(isWallHopEnabled and "Pm-WallHop включен" or "Pm-WallHop выключен", 2)
    UpdateWallhopButtonState()
end)

-- Клавиша для ручного WallHop
wallhop_section:AddKeybind("WallHop Jump Key", "J", function()
    if isWallHopEnabled then
        performWallhop()
    else
        shared.Notify("WallHop выключен! Нажмите F или кнопку в меню", 2)
    end
end)

-- === Плавающая кнопка (как в Aimlock) ===
local WallhopBindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, Color3.new(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1, Color3.new(0.501961, 0.501961, 0.501961))
})

local __ACTIVE_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.0, 0.8, 0.4)),
    ColorSequenceKeypoint.new(0.6, Color3.new(0.0, 0.5, 0.3)),
    ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.8, 0.6))
})

local function safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then parent = game:GetService("CoreGui") end
    if not parent or typeof(parent) ~= "Instance" then
        parent = game.Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    local sg = parent:FindFirstChild("@wallhopstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@wallhopstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false

            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = UDim2.new(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true

            game:GetService("TweenService"):Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local releaseConn
            releaseConn = ODHX.Connect(game:GetService("UserInputService").InputEnded, function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        clickFunc()
                    end
                    releaseConn:Disconnect()
                end
            end)
        end
    end))

    maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(ODHX.Connect(game:GetService("UserInputService").InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = UDim2.new(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function WallhopBindableButtons.AddBButton(id, text, onFunc, offFunc)
    if WallhopBindableButtons.Buttons[id] then return WallhopBindableButtons.Buttons[id]:FindFirstChild("BindValue") end

    local buttonMaid = {}
    function buttonMaid:GiveTask(task)
        table.insert(buttonMaid._tasks or {}, task)
        return task
    end
    function buttonMaid:Destroy()
        if buttonMaid._tasks then
            for _, t in pairs(buttonMaid._tasks) do
                if typeof(t) == "RBXScriptConnection" then t:Disconnect()
                elseif typeof(t) == "Instance" then t:Destroy()
                elseif type(t) == "function" then t()
                end
            end
        end
    end
    buttonMaid._tasks = {}

    local screen = workspace.CurrentCamera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)

    local xPos = 0.1 + ((WallhopBindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.7 - (math.floor(WallhopBindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = UDim2.new(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = UDim2.new(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageButton.Image = ""
    ImageButton.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    ImageButton.BackgroundTransparency = 0.28
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    Instance.new("UICorner", ImageButton).CornerRadius = UDim.new(0, 1000)
    local outerButtonStroke = Instance.new("UIStroke", ImageButton)
    outerButtonStroke.Color = Color3.new(1, 1, 1)
    outerButtonStroke.Thickness = 2
    outerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local innerButtonStroke = Instance.new("UIStroke", ImageButton)
    innerButtonStroke.Color = Color3.fromRGB(105, 105, 112)
    innerButtonStroke.Transparency = 0.5
    innerButtonStroke.Thickness = 1
    innerButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ImageButton.Parent = GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local BindValue = Instance.new("BoolValue", ImageButton)
    BindValue.Name = "BindValue"

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.TextSize = 14
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Gradient = Instance.new("UIGradient", outerButtonStroke)
    Gradient.Name = "@Stroke"
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    })
    local innerButtonGradient = Gradient:Clone()
    innerButtonGradient.Rotation = 180
    innerButtonGradient.Parent = innerButtonStroke

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = 0.5
    sound.Parent = ImageButton

    local debounce = false
    local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    local function onClick()
        if debounce then return end
        debounce = true
        local fOut = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 1})
        fOut:Play()
        fOut.Completed:Wait()

        BindValue.Value = not BindValue.Value
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
            ColorSequenceKeypoint.new(0.22, Color3.fromRGB(250, 250, 252)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(70, 70, 78)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
        })
        if BindValue.Value then safecallback(onFunc) else safecallback(offFunc) end

        local fIn = game:GetService("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 0})
        fIn:Play()
        fIn.Completed:Wait()
        debounce = false
    end

    MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)
    buttonMaid:GiveTask(ODHX.Connect(game:GetService("RunService").RenderStepped, function()
        Gradient.Rotation = (Gradient.Rotation + 1) % 360
    end))

    WallhopBindableButtons.Buttons[id] = ImageButton
    WallhopBindableButtons.Maids[id] = buttonMaid
    WallhopBindableButtons.Count = WallhopBindableButtons.Count + 1
    return BindValue
end

function WallhopBindableButtons.DeleteBButton(id)
    if WallhopBindableButtons.Maids[id] then
        WallhopBindableButtons.Maids[id]:Destroy()
        WallhopBindableButtons.Maids[id] = nil
    end
    if WallhopBindableButtons.Buttons[id] then
        WallhopBindableButtons.Buttons[id]:Destroy()
        WallhopBindableButtons.Buttons[id] = nil
    end
end

-- Обновление состояния кнопки
UpdateWallhopButtonState = function()
    ODHX.Commit()
    local btn = WallhopBindableButtons.Buttons["wallhop_toggle"]
    if not btn then return end
    local value=btn:FindFirstChild("BindValue")
    if value then value.Value=isWallHopEnabled end
    local textLabel = btn:FindFirstChild("@Text")
    if textLabel then
        textLabel.Text = isWallHopEnabled and "ON" or "OFF"
    end
    local gradient = btn:FindFirstChild("@Stroke")
    if gradient then
        gradient.Color = isWallHopEnabled and __ACTIVE_COLOR or __NORMAL_COLOR
    end
end

-- Экранная кнопка WallHop полностью отключена по запросу пользователя.

-- --- Основная логика ---
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- --- Переменные ---
local isFlicking = false
local lastFlickTime = 0
local isJumpKeyPressed = false
local Camera = workspace.CurrentCamera
local wallDetectionCooldown = 0

-- --- Raycast параметры для WallHop ---
local wallRaycastParams = RaycastParams.new()
wallRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- --- Функция проверки, является ли объект игроком ---
local function isPlayerCharacter(instance)
    if not instance then return false end
    local current = instance
    while current do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            local players = Players:GetPlayers()
            for _, player in ipairs(players) do
                if player.Character == current then
                    return true
                end
            end
        end
        current = current.Parent
    end
    return false
end

-- --- Функция проверки, является ли объект стеной ---
local function isWall(instance)
    if not instance or not instance.IsA then return false end
    
    -- Игнорируем игроков
    if instance:IsA("Part") and instance.Parent and instance.Parent:IsA("Model") and instance.Parent:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Проверяем все родительские объекты на принадлежность игроку
    local current = instance
    while current do
        if isPlayerCharacter(current) then
            return false
        end
        current = current.Parent
    end
    
    -- Проверяем, что это часть с коллизией
    if not instance:IsA("BasePart") and not instance:IsA("Terrain") then
        return false
    end
    
    -- Проверяем CanCollide
    if instance:IsA("BasePart") and not instance.CanCollide then
        return false
    end
    
    return true
end

-- --- Функция получения результата Raycast для стены ---
local function getWallRaycastResult()
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Добавляем в черный список персонажи других игроков
    local players = Players:GetPlayers()
    local blacklist = {character}
    for _, player in ipairs(players) do
        if player ~= LocalPlayer and player.Character then
            table.insert(blacklist, player.Character)
        end
    end
    wallRaycastParams.FilterDescendantsInstances = blacklist
    
    local closestHit, minDistance = nil, detectionDistance
    local hrpCF = hrp.CFrame
    for i = 0,7 do
        local angle = math.rad(i*45)
        local dir = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
        local ray = workspace:Raycast(hrp.Position, dir * detectionDistance, wallRaycastParams)
        if ray and ray.Instance and ray.Distance < minDistance then
            local hitInstance = ray.Instance
            if isWall(hitInstance) then
                minDistance = ray.Distance
                closestHit = ray
            end
        end
    end
    return closestHit
end

-- --- Флинг (Видео флинг) ---
performVideoFlick = function()
    if not isWallHopEnabled then return end
    if isFlicking then return end
    isFlicking = true
    
    local char = LocalPlayer.Character
    if not char then isFlicking = false return end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then isFlicking = false return end
    
    -- Проверяем, жив ли игрок
    if hum.Health <= 0 then isFlicking = false return end
    
    -- Сохраняем текущее состояние
    local currentVel = hrp.Velocity
    
    -- Выполняем флинг
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hrp.Velocity = Vector3.new(currentVel.X, flickPower, currentVel.Z)
    
    -- Разворот камеры
    local startCFrame = Camera.CFrame
    Camera.CFrame = startCFrame * CFrame.Angles(0, math.rad(180), 0)
    
    task.wait(0.01)
    Camera.CFrame = startCFrame
    
    isFlicking = false
end

-- --- Wallhop (Новая версия) ---
performWallhop = function()
    if not isWallHopEnabled then return end
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and rootPart and humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then return end
    
    local wall = getWallRaycastResult()
    if not wall then return end

    -- Поворачиваем игрока к стене
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + wall.Normal)
    RunService.Heartbeat:Wait()
    
    if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.1)
    end
end

-- --- Обнаружение стыков стен (Видео флинг) ---
local lastHitInstance = nil
local currentHitInstance = nil

ODHX.Connect(RunService.Heartbeat, function()
    if not isWallHopEnabled or isFlicking then return end
    
    local char = LocalPlayer.Character
    if not char then 
        lastHitInstance = nil
        return 
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then 
        lastHitInstance = nil
        return 
    end
    
    -- Проверяем, зажат ли пробел
    if not isJumpKeyPressed then 
        lastHitInstance = nil
        return 
    end
    
    -- Создаем Raycast с улучшенной фильтрацией
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    -- Пускаем луч в направлении камеры
    local direction = Camera.CFrame.LookVector * detectionDistance
    local result = workspace:Raycast(hrp.Position, direction, raycastParams)
    
    currentHitInstance = nil
    
    if result then
        local hitInstance = result.Instance
        
        -- Проверяем, является ли объект стеной
        if isWall(hitInstance) then
            currentHitInstance = hitInstance
            
            -- Проверяем смену стены (стык)
            if lastHitInstance and lastHitInstance ~= currentHitInstance then
                local currentTime = os.clock()
                if currentTime - lastFlickTime > 0.1 then
                    lastFlickTime = currentTime
                    performVideoFlick()
                end
            end
        end
    end
    
    lastHitInstance = currentHitInstance
end)

-- --- Автоматический Wallhop при прыжке (только если включен) ---
ODHX.Connect(UserInputService.JumpRequest, function()
    if isWallHopEnabled then
        performWallhop()
    end
end)

-- --- Отслеживание нажатия на прыжок ---
ODHX.Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isJumpKeyPressed = true
    end
end)

ODHX.Connect(UserInputService.InputEnded, function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isJumpKeyPressed = false
        -- Сбрасываем детекцию при отпускании пробела
        lastHitInstance = nil
    end
end)

-- --- Сброс состояния при респавне ---
ODHX.Connect(LocalPlayer.CharacterAdded, function(character)
    lastHitInstance = nil
    currentHitInstance = nil
    isFlicking = false
end)

-- --- Дополнительно: сброс при потере фокуса ---
ODHX.Connect(UserInputService.WindowFocused, function()
    -- Если окно потеряло фокус, сбрасываем состояние прыжка
    isJumpKeyPressed = false
    lastHitInstance = nil
end)

ODHX.Bind("Pm-WallHop", "Включить WallHop", "Toggle", function() return isWallHopEnabled end)
ODHX.Bind("Pm-WallHop", "Дистанция обнаружения", "Slider", function() return detectionDistance end)
ODHX.Bind("Pm-WallHop", "Сила флинга", "Slider", function() return flickPower end)
ODHX.cleanup=function()
    for id in pairs(WallhopBindableButtons.Buttons) do WallhopBindableButtons.DeleteBButton(id) end
end
ODHX.Finish()

        end, function(__error) return tostring(__error) end)
        if not __pluginOk then
            warn("[Noir embedded plugin: Pm-Wallhop.lua.txt] " .. tostring(__pluginError))
            notify("Pm-Wallhop.lua.txt failed to load: " .. tostring(__pluginError), 7)
        end
    end
end
